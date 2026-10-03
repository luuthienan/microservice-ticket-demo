class PaymentCreatedListener
  def self.subject = "payment:created"

  def handle(data)
    OrderCompletion.new(order: Order.find(data["order_id"])).call
  end
end
