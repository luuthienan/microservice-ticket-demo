# Where Events travel: one Kafka topic per service that owns the data (see docs/adr/0002).
module EventBus
  TOPICS = { "ticket" => "tickets.events", "order" => "orders.events", "payment" => "payments.events" }.freeze

  # "ticket:updated" -> "tickets.events"
  def self.topic_for(subject) = TOPICS.fetch(subject.split(":").first)

  def self.dead_letter_topic_for(topic) = "#{topic}.dlt"

  # The service this process belongs to, sent with every Event.
  def self.producer_name = Rails.application.class.module_parent_name.downcase

  def self.producer
    config("enable.idempotence" => true, "acks" => "all").producer
  end

  # Offsets are committed by hand, only once an Event has been handled.
  def self.consumer(group)
    config("group.id" => group, "enable.auto.commit" => false, "enable.auto.offset.store" => false,
           "auto.offset.reset" => "earliest").consumer
  end

  def self.config(settings = {})
    Rdkafka::Config.new({ "bootstrap.servers" => ENV.fetch("KAFKA_BROKERS") }.merge(settings))
  end
end
