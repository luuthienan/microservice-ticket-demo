namespace :events do
  desc "Listen for events from other services"
  task listen: :environment do
    $stdout.sync = true
    EventConsumer.new("orders-service", [
      TicketCreatedListener, TicketUpdatedListener, ExpirationCompleteListener, PaymentCreatedListener
    ]).listen
  end
end
