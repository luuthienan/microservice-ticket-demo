import { useEffect, useState } from "react";
import Link from "next/link";
import { loadStripe } from "@stripe/stripe-js";
import { CardElement, Elements, useElements, useStripe } from "@stripe/react-stripe-js";
import useRequest from "../../hooks/use-request";

const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISH_KEY;
const stripePromise = publishableKey ? loadStripe(publishableKey) : null;

// Seconds until `expiresAt`, ticking every second. `null` until mounted so server and client markup match.
const useSecondsLeft = (expiresAt) => {
  const [secondsLeft, setSecondsLeft] = useState(null);

  useEffect(() => {
    const tick = () => setSecondsLeft(Math.max(0, Math.round((new Date(expiresAt) - Date.now()) / 1000)));
    tick();
    const timer = setInterval(tick, 1000);
    return () => clearInterval(timer);
  }, [expiresAt]);

  return secondsLeft;
};

const formatCountdown = (seconds) =>
  `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;

const PaymentForm = ({ orderId, onPaid }) => {
  const stripe = useStripe();
  const elements = useElements();
  const [cardError, setCardError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const { doRequest, errors } = useRequest({
    url: "/api/payments",
    method: "post",
    body: { orderId },
    onSuccess: onPaid,
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

const OrderShow = ({ order }) => {
  const secondsLeft = useSecondsLeft(order.expiresAt);
  const [paid, setPaid] = useState(false);

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
    if (order.status === "cancelled" || secondsLeft === 0) {
      return <div className="alert alert-warning">Order expired.</div>;
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
          <PaymentForm orderId={order.id} onPaid={() => setPaid(true)} />
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
      {renderPayment()}
    </div>
  );
};

OrderShow.getInitialProps = async (context, client, currentUser) => {
  const { orderId } = context.query;
  const { data } = await client.get(`/api/orders/${orderId}`);

  return { order: data };
};

export default OrderShow;
