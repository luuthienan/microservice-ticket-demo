import { useEffect, useState } from "react";
import Link from "next/link";
import Router from "next/router";
import axios from "axios";
import { loadStripe } from "@stripe/stripe-js";
import { CardElement, Elements, useElements, useStripe } from "@stripe/react-stripe-js";
import useRequest from "../../hooks/use-request";

const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISH_KEY;
const stripePromise = publishableKey ? loadStripe(publishableKey) : null;

// Seconds until `expiresAt`, ticking every second. `null` until mounted so server and client markup match.
const useSecondsLeft = (expiresAt) => {
  const [secondsLeft, setSecondsLeft] = useState(null);

  useEffect(() => {
    if (!expiresAt) return undefined; // a Pending order has no deadline yet
    const tick = () => setSecondsLeft(Math.max(0, Math.round((new Date(expiresAt) - Date.now()) / 1000)));
    tick();
    const timer = setInterval(tick, 1000);
    return () => clearInterval(timer);
  }, [expiresAt]);

  return secondsLeft;
};

const formatCountdown = (seconds) =>
  `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;

const POLL_INTERVAL_MS = 1000;
const MAX_POLLS = 60; // a payment that takes longer than this is left to My Orders

// Follows a payment the buyer submitted. The card is charged after the request returns, so ask until it is paid or
// failed, and give up after MAX_POLLS rather than spin for ever.
const usePaymentStatus = (paymentId) => {
  const [payment, setPayment] = useState(null);
  const [timedOut, setTimedOut] = useState(false);

  useEffect(() => {
    if (!paymentId) return undefined;

    setPayment(null);
    setTimedOut(false);
    let polls = 0;
    let finished = false;
    const timer = setInterval(async () => {
      polls += 1;
      try {
        const { data } = await axios.get(`/api/v1/payments/${paymentId}`);
        if (data.status !== "pending" && !finished) {
          finished = true;
          setPayment(data);
        }
      } catch (error) {
        // try again on the next tick
      }
      if (polls >= MAX_POLLS && !finished) {
        finished = true;
        setTimedOut(true);
      }
      if (finished) clearInterval(timer);
    }, POLL_INTERVAL_MS);
    return () => clearInterval(timer);
  }, [paymentId]);

  return { payment, timedOut };
};

const PaymentForm = ({ orderId, onRequested }) => {
  const stripe = useStripe();
  const elements = useElements();
  const [cardError, setCardError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const { doRequest, errors } = useRequest({
    url: "/api/v1/payments",
    method: "post",
    body: { order_id: orderId },
    onSuccess: onRequested,
  });

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!stripe || !elements) return;

    setSubmitting(true);
    setCardError(null);
    const { token, error } = await stripe.createToken(elements.getElement(CardElement));
    if (error) {
      setCardError(error.message);
    } else {
      await doRequest({ token: token.id });
    }
    setSubmitting(false);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="form-control p-3 mb-3">
        <CardElement options={{ hidePostalCode: true }} />
      </div>
      {cardError && <div className="alert alert-danger">{cardError}</div>}
      {errors}
      <button className="btn btn-primary" disabled={!stripe || submitting}>
        {submitting ? "Processing..." : "Pay"}
      </button>
    </form>
  );
};

// A Pending order has no deadline until the tickets service confirms its ticket, then it can be paid or,
// if the ticket changed in the meantime, it is cancelled. An order whose card is being charged is paid or goes back to
// awaiting payment. Reload the order until one of those happens.
const STATUSES_TO_WAIT_OUT = ["created", "payment_processing"];

const useRefreshWhilePending = (order) => {
  useEffect(() => {
    if (!STATUSES_TO_WAIT_OUT.includes(order.status)) return undefined;

    const timer = setInterval(() => Router.replace(Router.asPath), 1000);
    return () => clearInterval(timer);
  }, [order.status]);
};

const OrderShow = ({ order }) => {
  const secondsLeft = useSecondsLeft(order.expires_at);
  const [paid, setPaid] = useState(false);
  const [paymentId, setPaymentId] = useState(null);
  const [failure, setFailure] = useState(null);
  const { payment, timedOut } = usePaymentStatus(paymentId);
  useRefreshWhilePending(order);

  useEffect(() => {
    if (!payment) return;

    setPaymentId(null);
    if (payment.status === "paid") {
      setPaid(true);
    } else {
      setFailure(payment.failure_message);
      Router.replace(Router.asPath); // the order is on its way back to awaiting payment
    }
  }, [payment]);

  const handleRequested = ({ id }) => {
    setFailure(null);
    setPaymentId(id);
  };

  const renderPayment = () => {
    if (paid) {
      return (
        <div className="alert alert-success">
          Payment successful. <Link href="/">Back to tickets</Link>
        </div>
      );
    }
    if (order.status === "complete") {
      return <div className="alert alert-success">Already paid.</div>;
    }
    if (timedOut) {
      return (
        <div className="alert alert-warning">
          Your payment is taking longer than usual. Check <Link href="/orders">My Orders</Link> for the result.
        </div>
      );
    }
    if (paymentId || order.status === "payment_processing") {
      return <div className="alert alert-info">Processing payment...</div>;
    }
    if (order.status === "created") {
      return <div className="alert alert-info">Confirming that the ticket is still available...</div>;
    }
    if (order.status === "cancelled" || secondsLeft === 0) {
      return <div className="alert alert-warning">Order cancelled or expired.</div>;
    }
    if (!stripePromise) {
      return <div className="alert alert-danger">Payments are not configured.</div>;
    }
    return (
      <>
        <p>
          Time left to pay: <strong>{secondsLeft === null ? "--:--" : formatCountdown(secondsLeft)}</strong>
        </p>
        <Elements stripe={stripePromise}>
          <PaymentForm orderId={order.id} onRequested={handleRequested} />
        </Elements>
      </>
    );
  };

  return (
    <div>
      <h1>Order Details</h1>
      <p>Order ID: {order.id}</p>
      <p>Ticket Title: {order.ticket.title}</p>
      <p>Price: ${order.ticket.price}</p>
      {failure && !paid && <div className="alert alert-danger">Payment failed: {failure}</div>}
      {renderPayment()}
    </div>
  );
};

OrderShow.getInitialProps = async (context, client, currentUser) => {
  const { orderId } = context.query;
  const { data } = await client.get(`/api/v1/orders/${orderId}`);

  return { order: data };
};

export default OrderShow;
