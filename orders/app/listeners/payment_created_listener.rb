class PaymentCreatedListener
  def self.subject = "payment:created"

  def handle(data)
    Order.find(data["order_id"]).complete!
  end
end
