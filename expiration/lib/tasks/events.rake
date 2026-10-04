namespace :events do
  desc "Listen for events from other services"
  task listen: :environment do
    $stdout.sync = true
    EventConsumer.new("expiration-service", [OrderCreatedListener]).listen
  end
end
