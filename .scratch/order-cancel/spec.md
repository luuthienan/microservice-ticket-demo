# Buyer cancels an order

Status: ready-for-human

A **Buyer** can cancel their own order from the client.

## Decisions

- Cancellable: a Pending order, or an order awaiting payment whose deadline has not passed. Not Payment processing (ADR 0006), Paid or Cancelled.
- The "Cancel order" action is on each cancellable row of My Orders and on the Order Details page, after a confirm ("Cancel this order? This can't be undone.").
- The buyer stays on the page; it reloads and the order reads "Cancelled". The ticket is released and can be ordered again.
- A refusal ("Order cannot be cancelled", "Order changed, try again") is shown and the page reloads to the order's real state.
- No backend change: the client calls `DELETE /api/v1/orders/:id`.
