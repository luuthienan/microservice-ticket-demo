# Buyer Cancels Their Own Order (Client)

## Requirements
Let a Buyer release a ticket they no longer want by cancelling their own Pending or Awaiting-payment order from the web client, by exposing the already-built, tested cancellation capability of the orders service. Scope is the client only: no change to the orders, tickets or payments services, their API, Events or database. An order that a payment has claimed (Payment processing), is Paid, or is already Cancelled stays non-cancellable, and the Buyer is told clearly when the order changed since the page was loaded.

## Entities
```mermaid
classDiagram
direction TB

class Order {
    +Integer id
    +String status
    +String expires_at
    +Integer version
    +Ticket ticket
}

class Ticket {
    +Integer id
    +String title
    +Number price
}

class CancelOrderButton {
    +Integer orderId
    +render()
}

class OrderIndex {
    +Order[] orders
}

class OrderShow {
    +Order order
}

class useRequest {
    +doRequest()
    +errors
}

Order "1" -- "1" Ticket : for
OrderIndex "1" --> "*" Order : lists
OrderShow "1" --> "1" Order : shows
OrderIndex --> CancelOrderButton : row action
OrderShow --> CancelOrderButton : page action
CancelOrderButton --> useRequest : DELETE /api/v1/orders/:id
CancelOrderButton ..> Order : cancels
```
No new domain entity: `Order` is the existing API representation (`OrderSerializer`: id, status, user_id, expires_at, version, ticket). `CancelOrderButton` is the only new client component. Order status values are unchanged: `created`, `awaiting_payment`, `payment_processing`, `complete`, `cancelled`.

## Approach
1. Capability reuse:
   - The cancellation already exists end to end: `DELETE /api/v1/orders/:id` → `OrderCancellation` → `order:cancelled` Event → tickets releases the ticket, payments fails any pending payment. The client only calls it.
   - Rejected: a new `POST .../cancel` endpoint, cancellation during Payment processing, refunds (ADR 0006), and any optimistic UI that shows Cancelled before orders answers.
2. Client implementation:
   - One shared component, `CancelOrderButton`, used on My Orders rows and on Order Details, so confirmation, request and error handling exist once.
   - It follows the seller-cancel precedent in `pages/tickets/mine.js`: `window.confirm`, a `btn btn-link text-danger` button, `useRequest` for the call and for error rendering.
   - After the request finishes, successful or not, the page reloads its data with `Router.replace(Router.asPath)`. On success the order now reads Cancelled; on a 400/409 the Buyer sees the backend's message and the refreshed true state (the button disappears if the order is no longer cancellable).
   - The Buyer stays on the page they cancelled from.
3. Business logic:
   - The client decides visibility with one predicate that mirrors the backend rule: cancellable when the order is Pending (`created`), or Awaiting payment (`awaiting_payment`) and not past its deadline. Past-deadline orders are already presented as Cancelled and get no button.
   - The backend remains the authority: ownership (401), state (400 "Order cannot be cancelled") and concurrency (409 "Order changed, try again") are enforced there and only displayed here.
   - Risk carried to verification: confirm that `order:cancelled` reaching tickets before the reservation of a Pending order is applied cannot leave the ticket Reserved (see Safeguards).

## Structure

### Inheritance Relationships
1. `CancelOrderButton` is a plain function component (no inheritance), exported as default from `client/components/cancel-order-button.js`.
2. `isOrderCancellable` is a plain exported function in the same file.

### Dependencies
1. `CancelOrderButton` depends on `useRequest` (`client/hooks/use-request.js`) and `next/router`.
2. `pages/orders/index.js` (`OrderIndex`) imports `CancelOrderButton` and `isOrderCancellable`.
3. `pages/orders/[orderId].js` (`OrderShow`) imports `CancelOrderButton` and `isOrderCancellable`.
4. At runtime the button calls the orders service through the existing nginx `/api/v1/orders` route; no new route.

### Layered Architecture
1. Page layer (`pages/orders/*`): decides where the action is placed and passes the order id.
2. Component layer (`components/cancel-order-button.js`): confirmation, request, error display, refresh.
3. Hook layer (`hooks/use-request.js`): HTTP call and error-to-message conversion; unchanged.
4. Service layer (orders API): state, ownership and concurrency rules; unchanged.
5. Error handling: the backend's `{ errors: [{ message }] }` is rendered by `useRequest` as an alert; no client-side exception handler is added.

## Operations

### Create Component - CancelOrderButton (`client/components/cancel-order-button.js`)
1. Responsibility: let the Buyer cancel one order after confirming, then refresh the page's data.
2. Exports:
   - `isOrderCancellable(order, now = Date.now())`: Boolean
     - Logic:
       - `order.status === "created"` → true.
       - `order.status === "awaiting_payment"` → true only when `order.expires_at` is present and `new Date(order.expires_at) > now`.
       - any other status → false.
   - default `CancelOrderButton({ orderId, className })`
3. Behaviour of `CancelOrderButton`:
   - `useRequest({ url: `/api/v1/orders/${orderId}`, method: "delete" })`, with no `onSuccess`.
   - `cancel` is async: if `window.confirm("Cancel this order? This can't be undone.")` is false, do nothing; otherwise set `submitting` true, `await doRequest()`, then `Router.replace(Router.asPath)`, then set `submitting` false.
   - Refreshing after both outcomes is deliberate: a failed cancel (400/409) means the order's state changed, and the refreshed page shows the true state.
   - Render a fragment: a `<button>` with classes `btn btn-link text-danger p-0` plus the `className` prop, `onClick={cancel}`, `disabled={submitting}`, labelled "Cancel order", followed by `{errors}`.
4. Constraints: the button must be disabled while the request is in flight so a double click sends one request; it never decides authorization.

### Update Page - My Orders (`client/pages/orders/index.js`)
1. Responsibility: show the Cancel action on cancellable rows.
2. Changes:
   - Import `CancelOrderButton, { isOrderCancellable }`.
   - In the existing row link cell (`<td>` with the View/Pay link), after the `Link`, render `{isOrderCancellable(order) && <CancelOrderButton orderId={order.id} className="ms-3" />}`.
   - Leave `describeOrder` and its labels unchanged.
3. Constraints: no change to columns, statuses labels, sign-in redirect or ordering.

### Update Page - Order Details (`client/pages/orders/[orderId].js`)
1. Responsibility: offer cancellation next to the payment form for a cancellable order.
2. Changes:
   - Import `CancelOrderButton, { isOrderCancellable }`.
   - In `OrderShow`, after `{renderPayment()}`, render `{!paid && !paymentId && isOrderCancellable(order) && <div className="mt-3"><CancelOrderButton orderId={order.id} /></div>}`.
   - `paid` and `paymentId` guard against cancelling while the Buyer's own payment is being submitted or has just succeeded; the backend guard still applies if they race.
3. Constraints: `renderPayment`, polling hooks and countdown remain unchanged. A cancelled order already renders "Order cancelled or expired.", so no new message is required. For a Pending order the existing "Confirming that the ticket is still available..." message is shown with the Cancel action beside it (the documented escape hatch of ADR 0005).

### Add Spec Note - Order cancel (`.scratch/order-cancel/spec.md`)
1. Responsibility: record the decisions per the repository's local-markdown convention.
2. Content: Status `ready-for-human`; rules (Buyer cancels own Pending/Awaiting-payment order; not Payment processing, Paid, Cancelled); placement (My Orders row and Order Details); confirm text; stays on the page; backend unchanged (`DELETE /api/v1/orders/:id`).

### Verify (no code)
1. Run the existing orders request and service specs for cancellation to confirm the unchanged contract: `bundle exec rspec spec/requests/api/v1/orders_spec.rb spec/services/order_cancellation_spec.rb` in `orders/`.
2. The client has no test runner; verify manually in the running stack:
   - Pending and Awaiting-payment: cancel → row/page reads Cancelled, ticket appears Available on the landing page.
   - Payment processing, Paid, Cancelled, past-deadline orders: no Cancel button.
   - Stale page (order paid in another tab) → backend message "Order cannot be cancelled" shown, page refreshes, button gone.
   - Declining the confirm sends no request; a double click sends one request.
   - Check the Pending-order ordering risk: cancel immediately after placing an order and confirm the ticket ends Available.

## Norms
1. Annotation Standards: not applicable (JavaScript/React); function components with hooks, default export per file for pages and components, as in `components/header.js` and `pages/tickets/mine.js`.
2. Dependency Injection: hooks and imports only; HTTP goes through `useRequest`, never raw `axios` in the component.
3. Exception Handling:
   - Rely on `useRequest` to turn `{ errors: [{ message }] }` into the shared danger alert; fall back to "Something went wrong".
   - Do not swallow errors silently and do not add client-side error classes.
4. Data Validation: the client validates nothing about the order itself beyond hiding the action; the backend is authoritative.
5. Logging: none, matching the existing client.
6. Documentation Standards: short comments only for non-obvious reasons (why the page refreshes after a failure too); style matches the surroundings: 2-space indent, double quotes, semicolons, Bootstrap utility classes. Use the Ubiquitous Language of `CONTEXT.md` (Buyer, Pending, Awaiting payment, Payment processing, Cancelled).

## Safeguards
1. Functional Constraints: only Pending and non-expired Awaiting-payment orders show the action; a cancelled order is never revived; cancelling an order does not cancel its ticket (the ticket returns to Available).
2. Performance Constraints: one `DELETE` and one page data reload per cancel; no polling added to My Orders.
3. Security Constraints: authorization is enforced only by the orders service (401 for another user's order); the client sends no user id and the button is never treated as a security boundary.
4. Integration Constraints: do not modify the orders API, its error messages, Events (`order:cancelled`), or the tickets and payments services; do not change `useRequest`'s contract.
5. Business Rule Constraints: Payment processing orders are never cancellable (ADR 0006: no refunds); an Awaiting-payment order past its deadline is shown as Cancelled and gets no action.
6. Exception Handling Constraints:
   - Backend messages ("Order cannot be cancelled", "Order changed, try again") are shown as received.
   - No internal details are exposed; unknown failures show "Something went wrong".
7. Technical Constraints: no new dependencies; no change to `package.json`; no modal library (native `window.confirm`, as on My Tickets).
8. Data Constraints: the order id comes from the order object returned by the API; the URL is built only from it.
9. API Constraints: use `DELETE /api/v1/orders/:id` exactly; expect 204 on success and treat 400, 401, 404 and 409 as displayable failures.
10. Verification Constraint: before declaring done, confirm the Pending-order race: when a Buyer cancels a Pending order, `order:cancelled` must still release the ticket even if it is processed around the same time as the reservation. If the ticket can stay Reserved, stop and report it as a separate backend issue rather than changing services under this task.
