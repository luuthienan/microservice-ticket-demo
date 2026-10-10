# Let a seller withdraw a ticket

Status: ready-for-human

The `cancelled` ticket status exists and is guarded (a cancelled ticket can't be ordered or edited), but nothing sets it yet. Add the action that lets a seller withdraw their listing, moving it `available -> cancelled` (terminal). Publish `ticket:updated` so orders' Copy follows.

Rules to decide before building (not settled yet):

- Can a seller withdraw a ticket that is Reserved (an unpaid order exists)? If yes, what happens to that order: cancel it, or let it expire first?
- Can a seller withdraw a Sold ticket? Probably not, since the buyer has paid.
- How is it exposed: a `DELETE /api/v1/tickets/:id`, or an explicit action?
- How does the client show a Cancelled ticket in the list?

See `docs/adr/0004-ticket-status-source-of-truth.md` and the Ticket status terms in `CONTEXT.md`.
