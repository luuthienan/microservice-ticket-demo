# Sends outbox rows to Kafka in id order and marks them published (see docs/adr/0003).
# Delivery is at-least-once: a crash after Kafka accepts a row but before it is marked sends it again.
class OutboxRelay
  POLL_INTERVAL = 0.5
  BATCH_SIZE = 100
  RETENTION = 7.days
  PURGE_INTERVAL = 1.hour
  LOCK_KEY = Zlib.crc32("outbox_relay")

  def initialize(producer: nil)
    @producer = producer
    @last_purge = Time.current
  end

  # Runs forever, once this process holds the advisory lock. Only one relay per database may send,
  # or the order would be lost.
  def run
    sleep POLL_INTERVAL until lock_acquired?
    Rails.logger.info("[OutboxRelay] lock acquired, relaying outbox events")
    loop do
      sleep POLL_INTERVAL if relay_pending.zero?
      purge_published
    end
  end

  # Sends the oldest unpublished rows, one at a time and in order. Returns how many were sent.
  def relay_pending
    OutboxEvent.pending.limit(BATCH_SIZE).each { |event| send_event(event) }.size
  end

  def purge_published
    return if Time.current - @last_purge < PURGE_INTERVAL

    purged = OutboxEvent.where(published_at: ...RETENTION.ago).delete_all
    Rails.logger.info("[OutboxRelay] purged count=#{purged}") if purged.positive?
    @last_purge = Time.current
  end

  private

  def producer
    @producer ||= EventBus.producer
  end

  def lock_acquired?
    OutboxEvent.lease_connection.select_value("SELECT pg_try_advisory_lock(#{LOCK_KEY})")
  end

  def send_event(event)
    topic = EventBus.topic_for(event.subject)
    report = producer.produce(
      topic:, key: event.entity_id.to_s, payload: event.payload.to_json,
      headers: { "subject" => event.subject, "event_id" => event.id.to_s,
                 "occurred_at" => event.occurred_at.iso8601(3), "producer" => EventBus.producer_name }
    ).wait
    event.update_columns(published_at: Time.current)
    Rails.logger.info("[OutboxRelay] published subject=#{event.subject} event_id=#{event.id} entity_id=#{event.entity_id} " \
                      "topic=#{topic} partition=#{report&.partition} offset=#{report&.offset} payload=#{event.payload.to_json}")
  end
end
