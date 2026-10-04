# Consumes events from Kafka: one consumer group per service, one topic per owning service.
# Each listener class responds to `.subject` and `#handle(data)`. An event's offset is committed only
# when its handler succeeds. A failing event is retried in place, pausing only its partition so the
# others keep flowing; after MAX_ATTEMPTS it goes to the topic's dead-letter topic and is skipped.
class EventConsumer
  MAX_ATTEMPTS = 5
  POLL_TIMEOUT_MS = 1_000

  attr_reader :group

  def initialize(group, listeners, consumer: nil, producer: nil)
    @group = group
    @handlers = listeners.index_by(&:subject)
    @consumer = consumer
    @producer = producer
    @attempts = Hash.new(0)
    @resume_at = {}
  end

  def topics
    @handlers.keys.map { |subject| EventBus.topic_for(subject) }.uniq
  end

  # Runs forever.
  def listen
    consumer.subscribe(*topics)
    loop { poll }
  end

  # One pass: resume partitions whose backoff is over, then handle at most one message.
  def poll
    resume_due_partitions
    message = consumer.poll(POLL_TIMEOUT_MS)
    process(message) if message
  end

  private

  def consumer
    @consumer ||= EventBus.consumer(@group)
  end

  def producer
    @producer ||= EventBus.producer
  end

  def process(message)
    listener = @handlers[message.headers&.fetch("subject", nil)]
    listener&.new&.handle(JSON.parse(message.payload))
    succeeded(message)
  rescue => e
    failed(message, e)
  end

  def succeeded(message)
    @attempts.delete(position(message))
    consumer.store_offset(message)
    consumer.commit(nil, false)
  end

  def failed(message, error)
    attempts = @attempts[position(message)] += 1
    if attempts >= MAX_ATTEMPTS
      dead_letter(message, error, attempts)
      succeeded(message)
    else
      retry_later(message, error, attempts)
    end
  end

  # Rewinds to the failed message and pauses its partition for 1, 2, 4, 8 seconds.
  def retry_later(message, error, attempts)
    delay = 2**(attempts - 1)
    warn "#{message.topic}[#{message.partition}]@#{message.offset} failed (attempt #{attempts}), retrying in #{delay}s: " \
         "#{error.class}: #{error.message}"
    consumer.seek(message)
    consumer.pause(partition_list(message.topic, message.partition))
    @resume_at[[message.topic, message.partition]] = Time.current + delay
  end

  def resume_due_partitions
    @resume_at.select { |_, time| time <= Time.current }.each_key do |topic, partition|
      @resume_at.delete([topic, partition])
      consumer.resume(partition_list(topic, partition))
    rescue Rdkafka::RdkafkaError
      nil # the partition was reassigned in the meantime
    end
  end

  def dead_letter(message, error, attempts)
    warn "#{message.topic}[#{message.partition}]@#{message.offset} dead-lettered: #{error.class}: #{error.message}"
    producer.produce(
      topic: EventBus.dead_letter_topic_for(message.topic), key: message.key, payload: message.payload,
      headers: (message.headers || {}).merge(
        "error" => "#{error.class}: #{error.message}", "attempts" => attempts.to_s, "original_topic" => message.topic,
        "original_partition" => message.partition.to_s, "original_offset" => message.offset.to_s
      )
    ).wait
  end

  def position(message) = [message.topic, message.partition, message.offset]

  def partition_list(topic, partition)
    Rdkafka::Consumer::TopicPartitionList.new.tap { |list| list.add_topic_and_partitions_with_offsets(topic, { partition => nil }) }
  end
end
