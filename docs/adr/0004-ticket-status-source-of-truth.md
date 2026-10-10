# Ticket status is stored, and the tickets service learns of payment from `order:completed`

A ticket's status (available, reserved, sold, cancelled) is a stored column in the tickets service, the source of truth for where the ticket stands, instead of being derived from `order_id`. `order_id` stays as the order that currently holds the ticket, set while it is reserved or sold and null otherwise; check constraints keep the two consistent.

Nothing told the tickets service that a ticket was paid for, because payments publishes `payment:created` and only orders consumes it. We made orders publish `order:completed` from `OrderCompletion`, and tickets consumes that, instead of tickets also listening to `payment:created`. Whether an Order is paid is orders' fact (ADR 0002 keeps each topic with the service that owns the data), `payment:created` carries an order id but no ticket id, and this way every Order state change that matters to another service is an Event with a Version.

Orders' Copy of a ticket stores the status, and an order is only accepted for a ticket whose Copy is Available. The Copy can lag behind a cancellation, so right after an order is cancelled a new order for that ticket can be refused until the `ticket:updated` that frees it arrives. We accepted that: the unique index on active orders still decides any race, and a refusal is safe where a double sale is not.
