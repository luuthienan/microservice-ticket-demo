# Bigint primary keys instead of uuid

Every service uses a sequential `bigint` primary key and `bigint` columns for ids that belong to other services. We started on uuid; with no production data, we reset the migration history rather than convert it. Bigint ids are smaller, index better and are easy to read in logs and events, at the cost of being guessable and only mintable by the database that owns the record.

Two rules follow from this:

- **A Copy's id comes from its source and is never generated locally.** The tables for `orders.tickets` and `payments.orders` have no default sequence, so creating a Copy without the source id fails instead of silently drawing an id that could collide with a later one.
- **Services accept only an integer `id` claim in the JWT.** Rails casts a string to an integer by its leading digits, so a stale uuid-era token could otherwise be read as another user's id.

Since ids are guessable, ownership must be checked on every read of a user's record (orders and payments already do this), never inferred from an id being hard to find.
