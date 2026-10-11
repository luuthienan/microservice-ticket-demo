# SPDD Analysis: Buyer Cancels Their Own Order

## Original Business Requirement
allow users as buyers to cancel their orders.

## Domain Concept Identification

### Domain Concept Identification

#### Existing Concepts (from codebase)
- **Buyer**: the user who placed an Order; the orders service alone knows who they are (`CONTEXT.md`). Only the Buyer may cancel their order — already enforced by an ownership check in the orders service.
- **Order** (orders service, Rails/Postgres): lifecycle Pending (`created`) → Awaiting payment → Payment processing → Paid (`complete`), with Cancelled as a final state. Already carries a cancel transition reachable from Pending and Awaiting payment only.
- **Order cancellation** (backend, already built): `DELETE /api/v1/orders/:id` → `OrderCancellation` → marks the order cancelled and publishes `order:cancelled` in the same transaction (outbox). Returns 400 "Order cannot be cancelled" for Payment processing / Paid / Cancelled, 401 for another user's order, 404 for unknown, 409 when a concurrent change (e.g. a payment claim) wins. Covered by request and service specs.
- **Reservation / Ticket** (tickets service): `order:cancelled` makes tickets release a Reserved ticket back to Available (`TicketRelease`), only if the order is the one holding it. Payments' Copy of the order follows `order:cancelled` and fails any still-pending payment.
- **Order surfaces in the client**: "My Orders" list (`/orders`) and "Order Details" page (`/orders/[orderId]`). Both already render a Cancelled state; neither offers a way to cancel. The seller side already has a Cancel button with confirm on "My Tickets" — the established UI precedent.
- **System-initiated cancellation**: expiry (`ExpireOrderJob`) and rejected reservations reuse the same service without a user.

#### New Concepts Required
- **Buyer-facing "Cancel order" action**: the only missing piece. It is a client capability on top of an existing, tested backend capability; no new domain entity, table, Event or Subject is needed.

#### Key Business Rules
- A Buyer can cancel only their own order: Order.
- Cancellable states are Pending and Awaiting payment; not once a payment has claimed it (Payment processing), nor when Paid or already Cancelled (ADR 0006): Order.
- Cancelling frees the ticket to be ordered again; it does not cancel the ticket (distinct from the Seller's ticket cancellation): Order, Reservation, Ticket status.
- Cancelled is final; an order is never revived (ADR 0006): Order.
- Implicit: a cancellation must be atomic with its `order:cancelled` Event so the ticket is reliably released (already ensured by the outbox).
- Implicit: the UI must not offer the action when the backend would refuse it, and must still handle the refusal when state changed since the page loaded.

## Strategic Approach

### Strategic Approach

#### Solution Direction
- The backend already satisfies the requirement end to end (API, authorization, state guard, concurrency guard, Event propagation to tickets and payments). The gap is purely the **client**: expose a Cancel action to the Buyer.
- Data flow: Buyer clicks Cancel (after a confirm, as My Tickets does) → `DELETE /api/v1/orders/:id` through the existing request hook → on success the order shows as Cancelled (list refreshed / order page reloaded). Errors (400 not cancellable, 409 changed) are shown with the existing error rendering.
- Offer the action only for Pending and Awaiting payment orders, on both My Orders and Order Details; hide it for Processing payment, Paid, Cancelled and for an Awaiting-payment order past its deadline (the UI already presents that as Cancelled).
- Follow existing conventions: confirm dialog + danger-styled link button as in `tickets/mine`, Buyer-facing labels per `CONTEXT.md`, and a client behaviour description alongside existing `.scratch/` specs.

#### Key Design Decisions
- **Where the action lives (list, details page, or both)**: list gives speed, details page gives context next to the Pay form → recommend both, sharing one cancel component/behaviour.
- **Confirmation step**: cancellation is irreversible and releases the ticket to others → recommend a confirm, consistent with seller cancel.
- **Reuse `DELETE` vs. new endpoint**: the existing endpoint is RESTful, tested and used by nothing else on the client → reuse; no backend change.
- **Freshness of state**: a Pending/Payment-processing order auto-refreshes on the details page, but the list does not → rely on the backend guard (400/409) plus a clear message rather than adding polling to the list.
- **Backend hardening**: none required by the requirement; see risks for optional items.

#### Alternatives Considered
- Soft-cancel via a new `POST /orders/:id/cancel`: duplicates working behaviour and diverges from the existing contract → rejected.
- Allowing cancellation during Payment processing with refund: explicitly ruled out by ADR 0006 (no refunds; claim exists so a charge never meets a cancelled order) → rejected.
- Waiting for `order:cancelled` to reach tickets before showing Cancelled: orders owns order state, and the UI should reflect orders' answer → rejected.

## Risk & Gap Analysis

### Risk & Gap Analysis

#### Requirement Ambiguities
- **Is the request really client-only?** The requirement reads as a new capability, but the backend already exists (`DELETE /api/v1/orders/:id`, specs included). Needs confirmation that the intended scope is the missing Buyer UI and not additional backend behaviour.
- **Which states are cancellable?** Not stated. The analysis assumes the existing rule (Pending, Awaiting payment). Confirm Buyers should not be able to cancel during Payment processing.
- **Where should the action appear?** My Orders, Order Details, or both is unspecified; assumed both.
- **Feedback wording and confirm text** are unspecified; assumed to mirror seller cancel.
- **Redirect after cancel**: stay on the page showing Cancelled, or return to My Orders? Unspecified.

#### Edge Cases
- Payment claim races the cancel: backend returns 409 "Order changed, try again"; the UI must show it and refresh so the order is not shown as cancellable when it is now Processing payment.
- Order expired or became Paid while the page was open: 400 "Order cannot be cancelled"; UI should refresh to the true state. Expired-but-not-yet-cancelled orders (past deadline, job pending) still accept a cancel, which is harmless.
- Pending order cancelled before tickets confirms: orders ignores the late `ticket:reserved` and the order stays Cancelled, but tickets only releases a ticket it already holds. Whether `order:cancelled` can reach tickets before the reservation is applied was not verified here (the two Events travel on different topics); confirm during REASONS Canvas, since a miss would leave the ticket Reserved.
- Double click / repeated submit: second call gets 400; button should be disabled while in flight.
- Cancelling an order already shown Cancelled in a stale tab: 400, harmless.
- Payment form open on Order Details while cancelling: the form should disappear once cancelled.

#### Technical Risks
- **Silent stale list**: My Orders is server-rendered once and does not poll; a stale row can show a Cancel that is no longer valid → mitigated by backend guard and refresh on error.
- **Payments Copy lag**: payments learns of cancellation via `order:cancelled`; a pay attempt submitted just before is failed by `OrderCopyCancellation`, the Buyer sees a payment failure rather than a cancel confirmation → acceptable, consistent with ADR 0006.
- **Gap acknowledged in ADR 0005**: a Pending order whose confirmation never arrives holds the ticket; Buyer cancel is the documented escape hatch, so the Cancel action should explicitly be available for Pending orders.
- **No client test harness observed** for these pages; verification may rely on backend specs plus manual/browser checks.

#### Acceptance Criteria Coverage
No explicit acceptance criteria were provided. Derived criteria from the requirement and existing rules:

| AC# | Description | Addressable? | Gaps/Notes |
|-----|-------------|--------------|------------|
| 1 | A Buyer can cancel their own Pending or Awaiting-payment order from the client | Yes | Backend ready; client action missing |
| 2 | The ticket becomes available to order again after cancellation | Yes | Existing `order:cancelled` → `TicketRelease` |
| 3 | Orders in Payment processing, Paid or Cancelled cannot be cancelled and the UI does not offer it | Yes | Backend refuses; UI must hide/handle |
| 4 | A user cannot cancel another user's order | Yes | Backend returns 401 already |
| 5 | A concurrent change surfaces a clear message rather than a silent failure | Partial | Backend 409/400 exist; client messaging to define |
| 6 | The order shows as Cancelled after cancelling | Yes | Needs refresh/redirect decision |
