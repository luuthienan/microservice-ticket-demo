# Transactional outbox with a polling relay

Services that publish Events (`tickets`, `orders`, `payments`) write each Event to an `outbox_events` table in the same database transaction as the change it announces. A separate relay process per service reads unpublished rows in id order and produces them to Kafka. `EventPublisher#publish` only inserts the row and raises when no transaction is open.

Publishing straight to the broker after the commit loses the Event if the process dies in between, leaving other services' Copies permanently behind. The outbox makes the change and its announcement succeed or fail together. A polling relay was chosen over change-data-capture (Debezium) because it needs no extra infrastructure.

The relay can send an Event twice (it crashes after Kafka accepts a message but before marking the row published), so delivery is at-least-once and consumers are idempotent. The outbox row id is the `event_id` header, unique only together with the producing service. A single relay per service, enforced with a Postgres advisory lock, keeps the order. Published rows are purged after seven days; Kafka is the long-term log.
