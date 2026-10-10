# microservice-ticket-demo

A ticket marketplace split into small services, written in Ruby on Rails 8 (Ruby 3.4.9, Postgres 18).
It is a rewrite of the Node.js `ticketing` demo; the Next.js client is unchanged.

| Service      | Purpose                                                        | Database          |
| ------------ | -------------------------------------------------------------- | ----------------- |
| `auth`       | Sign up, sign in, sign out, current user (JWT in a cookie)     | `auth_*`          |
| `tickets`    | Create, edit and list tickets; locks a ticket while it is ordered | `tickets_*`    |
| `orders`     | Create and cancel orders; orders wait for the ticket to be confirmed, then expire after 1 minute by default (Sidekiq) | `orders_*`    |
| `payments`   | Charge an order with Stripe                                    | `payments_*`      |
| `client`     | Next.js frontend                                               |                   |

`nginx` routes `/api/v1/users`, `/api/v1/tickets`, `/api/v1/orders` and `/api/v1/payments` to the services and everything else to the client.

## Events

Services talk through Kafka: one topic per service that owns the data (`tickets.events`, `orders.events`,
`payments.events`), one consumer group per service. The Subject (`ticket:updated`) travels in a message
header and the message is keyed by the entity's id, so all events for one record stay in order.
See `docs/adr/0002-kafka-topic-per-owning-service.md`.

```
ticket:created, ticket:updated  tickets  -> orders
ticket:reserved                 tickets  -> orders
ticket:reservation-rejected     tickets  -> orders
order:created                   orders   -> tickets
order:awaiting_payment          orders   -> payments
order:cancelled                 orders   -> tickets, payments
order:completed                 orders   -> tickets
payment:created                 payments -> orders
```

**Publishing.** A service writes each event to its `outbox_events` table in the same transaction as the change it
announces. `<service>-relay` (`bin/rails events:relay`) sends rows to Kafka in id order and marks them published;
published rows are purged after 7 days. Delivery is at-least-once (`docs/adr/0003-transactional-outbox-with-polling-relay.md`).

**Consuming.** An offset is committed only after the handler succeeds. A failing event is retried in place with
backoff (1, 2, 4, 8 s) while the other partitions keep flowing; after 5 attempts it goes to `<topic>.dlt` with the
error and its original topic, partition and offset in headers, and the consumer moves on.

Copies of another service's data (the ticket copy in `orders`, the order copy in `payments`) carry a `version`.
An update is applied only when it is exactly one version ahead. One the copy already has is ignored, so handling an
event twice is harmless. A gap raises and goes through the retry and dead-letter path.

**Reservation.** An order starts Pending and carries the version of the ticket copy it was placed from. `tickets`
reserves the ticket only if it is still available at that version (the check is part of the same optimistic-lock
`UPDATE`, so a seller's edit and a reservation can't both win) and publishes `ticket:reserved`; `orders` then moves
the order to awaiting payment. Otherwise `tickets` publishes `ticket:reservation-rejected` and `orders` cancels
the order. See `docs/adr/0005-tickets-confirms-reservations.md`.

Order expiry is not an event: when an order becomes awaiting payment, `orders` schedules a Sidekiq job (Redis holds
the jobs) and the job cancels the order if it is still unpaid. The window is `EXPIRATION_WINDOW_SECONDS`
(default 60). A Pending order has no deadline.

### Replay

Replaying moves a consumer group's committed offsets back so its listeners read the events again. Stop the
listener first, then reset and start it:

```sh
docker compose stop orders-listener
docker compose run --rm orders bin/rails events:replay FROM=earliest      # or timestamp:2026-10-04T09:00:00Z, or offset:<partition>:<n>
docker compose start orders-listener
```

To rebuild a service's copies from scratch, also empty the copy table first (`orders.tickets`, `payments.orders`).
Topics keep events forever, so `FROM=earliest` always has the full history.

### Monitoring

Kafka UI at <http://localhost:8081>: topics, messages (key, headers), dead-letter topics and each consumer
group's offsets and lag.

## Run

```sh
cp .env.example .env        # set STRIPE_KEY to a Stripe test secret key
docker compose up --build
```

Open <http://localhost:8080>.

## Test

```sh
docker compose run --rm tickets bundle exec rspec   # or auth, orders, payments
```

The first run of each service creates its databases and `db/schema.rb`.
