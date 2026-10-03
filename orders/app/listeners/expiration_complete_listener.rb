class ExpirationCompleteListener
  def self.subject = "expiration:complete"

  # An order that is no longer cancellable is a no-op, so the event is still acked.
  def handle(data)
    OrderCancellation.new(order: Order.find(data["order_id"])).call
  end
end
