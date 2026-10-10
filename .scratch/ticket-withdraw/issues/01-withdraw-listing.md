# Let a seller cancel an available ticket

Status: ready-for-human

The `cancelled` ticket status existed and was guarded (a cancelled ticket can't be ordered or edited), but nothing set it. A **Seller** can now cancel their own **Available** ticket from the My Tickets page, moving it `available -> cancelled` (terminal). `ticket:updated` is published so orders' Copy follows.

## Decisions

- Only an Available ticket can be cancelled. A Reserved, Sold or already Cancelled ticket is refused with 400 `Cannot cancel a <status> ticket`. Cancelling a Reserved ticket is open: see `02-cancel-reserved-ticket.md`.
- Exposed as the explicit action `POST /api/v1/tickets/:id/cancel`, not `DELETE`, because the ticket stays and only its status changes. It requires sign in; an unknown ticket is 404, a user who is not the seller is 401 (as for editing), a reservation that wins the race is 409.
- The status change bumps `lock_version`, so a reservation made against the old Version is rejected (ADR 0005).
- On My Tickets, an Available row shows a Cancel button next to View, behind a confirm. After a cancel the row stays and shows "Cancelled". Other statuses show no button.

See `docs/adr/0004-ticket-status-source-of-truth.md`, `docs/adr/0005-tickets-confirms-reservations.md` and the Ticket status terms in `CONTEXT.md`.
