# My Tickets page

Status: ready-for-human

A signed-in **Seller** can see the tickets they listed, in every status, on one page.

## Decisions

- "My tickets" are the tickets the user listed for sale. What the user bought stays on My Orders.
- All four ticket statuses are shown (Available, Reserved, Sold, Cancelled), newest first. No filters, no pagination.
- A row shows Title, Price, Status and a View link to the ticket page. It shows no Buyer, and has no Edit or Withdraw action (see `.scratch/ticket-withdraw/`).
- With no tickets the page says "You have no tickets yet."; the New Ticket button is always shown.
- The page is at `/tickets/mine`, linked from the header as "My Tickets" (signed-in users only, before "My Orders"). Signed-out visitors are redirected to `/auth/signin`.
- The tickets service serves it at `GET /api/v1/tickets/mine` (requires sign in). The public `GET /api/v1/tickets` is unchanged.
- The ticket status labels are shared by the landing page, the ticket page and My Tickets.
