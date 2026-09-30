# microservice-ticket-demo

A ticket marketplace split into small services, written in Ruby on Rails 8 (Ruby 3.4.9, Postgres 18).
It is a rewrite of the Node.js `ticketing` demo; the Next.js client is unchanged.

| Service      | Purpose                                                        | Database          |
| ------------ | -------------------------------------------------------------- | ----------------- |
| `auth`       | Sign up, sign in, sign out, current user (JWT in a cookie)     | `auth_*`          |
| `tickets`    | Create, edit and list tickets; locks a ticket while it is ordered | `tickets_*`    |
| `orders`     | Create and cancel orders; orders expire after 15 minutes       | `orders_*`        |
| `payments`   | Charge an order with Stripe                                    | `payments_*`      |
| `expiration` | Fires `expiration:complete` when an order's time is up (Sidekiq) | none            |
| `client`     | Next.js frontend                                               |                   |

`nginx` routes `/api/users`, `/api/tickets`, `/api/orders` and `/api/payments` to the services and everything else to the client.

## Events

Services talk through Redis Streams: one stream per event, one consumer group per service.
An event is acknowledged only after its handler succeeds, and is redelivered otherwise.

```
ticket:created, ticket:updated  tickets  -> orders
order:created                   orders   -> tickets, payments, expiration
order:cancelled                 orders   -> tickets, payments
expiration:complete             expiration -> orders
payment:created                 payments -> orders
```

Copies of another service's data (the ticket copy in `orders`, the order copy in `payments`) carry a `version`.
An update is applied only when it is exactly one version ahead; otherwise it is retried.

## Run

```sh
cp .env.example .env        # set STRIPE_KEY to a Stripe test secret key
docker compose up --build
```

Open <http://localhost:8080>.

## Test

```sh
docker compose run --rm tickets bundle exec rspec   # or auth, orders, payments, expiration
```

The first run of each service creates its databases and `db/schema.rb`.
