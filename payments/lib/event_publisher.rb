# Records an Event in the outbox, inside the caller's transaction, so it exists exactly when the
# change it announces does. OutboxRelay sends it to Kafka after the commit (see docs/adr/0003).
class EventPublisher
  # The field of the payload that names the entity an Event is about. It is the Kafka message key,
  # so all Events for one entity stay in order.
  ENTITY_FIELD = Hash.new(:id).merge("payment:created" => :order_id).freeze

  def publish(subject, data)
    raise "Events must be published inside the transaction that changes the data" unless OutboxEvent.connection.transaction_open?

    EventBus.topic_for(subject)
    OutboxEvent.create!(subject:, entity_id: data.fetch(ENTITY_FIELD[subject]), payload: data, occurred_at: Time.current)
  end
end
