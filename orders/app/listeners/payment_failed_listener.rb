class PaymentFailedListener
  def self.subject = "payment:failed"

  def handle(data)
    OrderPaymentRelease.new(order: Order.find(data["order_id"]), payment_id: data["id"]).call
  end
end
