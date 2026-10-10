namespace :events do
  consumer = -> { EventConsumer.new("payments-service", [OrderCreatedListener, OrderAwaitingPaymentListener, OrderCancelledListener]) }

  desc "Listen for events from other services"
  task listen: :environment do
    $stdout.sync = true
    consumer.call.listen
  end

  desc "Send events from the outbox to Kafka"
  task relay: :environment do
    $stdout.sync = true
    OutboxRelay.new.run
  end

  desc "Replay events: stop the listener, then events:replay FROM=earliest|timestamp:<iso8601>|offset:<partition>:<offset>"
  task replay: :environment do
    group = consumer.call
    EventReplay.new(group.group, group.topics, from: ENV.fetch("FROM")).call
  end
end
