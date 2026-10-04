# One Kafka topic per owning service, keyed by entity id

Events travel over Kafka with one topic per service that owns the data (`tickets.events`, `orders.events`, `payments.events`), not one topic per Subject. The Subject is a message header, and the message key is the id of the entity the Event is about. Each topic has a `.dlt` dead-letter topic.

Kafka only orders messages within one partition of one topic. With a topic per Subject, `orders` could read `ticket:updated` before `ticket:created` for the same ticket, and the Version rule would depend on retries to sort it out. With a topic per owner keyed by entity id, every Event for one record arrives in the order it was written, so a gap in Versions means something is really missing.

The cost is that a Listener's service reads Events for Subjects it ignores and skips them by header, and that "Subject" no longer maps one-to-one to a topic. "Subject" stays the domain word; topic, partition and offset are infrastructure terms and are kept out of the glossary.

Event topics keep their messages forever (`retention.ms=-1`) so a service can rebuild its Copies by replaying from the start. Replay is a consumer-group offset reset, so every Listener has to be safe to run twice for the same Event.
