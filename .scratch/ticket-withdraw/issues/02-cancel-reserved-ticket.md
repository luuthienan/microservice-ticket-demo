# Decide whether a seller can cancel a reserved ticket

Status: needs-triage

A **Seller** can cancel an **Available** ticket (see `01-withdraw-listing.md`). A **Reserved** ticket is refused, because a buyer's order holds it and the tickets service has no way to cancel an order: only the orders service owns that.

Rules to decide before building (not settled yet):

- Should a seller be able to cancel a Reserved ticket at all? The buyer may be mid-payment.
- If yes, what happens to that order: cancel it straight away, or let it expire first and then cancel the ticket?
- If the order is cancelled, which service does it, and through which Event? `order:cancelled` currently makes the tickets service release the ticket (`TicketRelease`), which would clash with the ticket ending up Cancelled.
- How does the Buyer learn their order was cancelled because of the seller?
- What does the My Tickets row show while a Reserved ticket is waiting to be cancelled?

A Sold ticket stays out of scope: the buyer has paid.
