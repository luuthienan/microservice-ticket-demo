# A payment that succeeds after the order expired

Status: resolved

Payments checks its own Copy of the order, so a charge can succeed just as the expiry job cancels the order in orders. `OrderCompletion` then refuses the cancelled order, so no `order:completed` is published, the ticket goes back to Available, and the buyer has paid for nothing. This already happens today; the ticket `status` change neither causes nor fixes it.

Needs a decision on how to reconcile: refund the charge, honour the payment by reviving the order if the ticket is still free, or stop expiry from racing a payment in flight.

## Comments

Resolved by stopping expiry from racing a payment: payments now asks orders to claim the order (`payment:requested`)
and charges only after `order:payment_processing`. No refund path was built. See
`docs/adr/0006-orders-claims-orders-for-payment.md`.
