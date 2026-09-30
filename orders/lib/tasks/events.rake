namespace :events do
  desc "Listen for events from other services"
  task listen: :environment do
    $stdout.sync = true
    Events.listen("orders-service", [
      TicketCreatedListener, TicketUpdatedListener, ExpirationCompleteListener, PaymentCreatedListener
    ])
  end
end
