import { useState } from "react";
import Router from "next/router";
import useRequest from "../hooks/use-request";

// Mirrors the orders service: a Pending order, or one awaiting payment whose deadline has not passed, can be cancelled.
// Not once a payment has claimed it, nor when it is paid or already cancelled. The service has the final say.
export const isOrderCancellable = (order, now = Date.now()) => {
  if (order.status === "created") return true;
  if (order.status === "awaiting_payment") return Boolean(order.expires_at) && new Date(order.expires_at) > now;
  return false;
};

const CancelOrderButton = ({ orderId, className = "" }) => {
  const [submitting, setSubmitting] = useState(false);
  const { doRequest, errors } = useRequest({ url: `/api/v1/orders/${orderId}`, method: "delete" });

  const cancel = async () => {
    if (!window.confirm("Cancel this order? This can't be undone.")) return;

    setSubmitting(true);
    await doRequest();
    // Reload after a failure too: the order changed under the buyer, so show where it stands now.
    Router.replace(Router.asPath);
    setSubmitting(false);
  };

  return (
    <>
      <button className={`btn btn-link text-danger p-0 ${className}`} onClick={cancel} disabled={submitting}>
        Cancel order
      </button>
      {errors}
    </>
  );
};

export default CancelOrderButton;
