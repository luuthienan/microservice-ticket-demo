class PaymentPaidListener
  def self.subject = "payment:paid"

  # A payment the order is not claimed for (it was cancelled, or this is an earlier attempt) is a no-op,
  # so the event is still acked.
  def handle(data)
    OrderCompletion.new(order: Order.find(data["order_id"]), payment_id: data["id"]).call
  end
end
