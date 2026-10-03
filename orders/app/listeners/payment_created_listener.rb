class PaymentCreatedListener
  def self.subject = "payment:created"

  # A payment for a cancelled order is a no-op, so the event is still acked.
  def handle(data)
    OrderCompletion.new(order: Order.find(data["order_id"])).call
  end
end
