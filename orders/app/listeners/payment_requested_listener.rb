class PaymentRequestedListener
  def self.subject = "payment:requested"

  # An order that is no longer awaiting payment (it was cancelled, say) is left as it is, so the event is still acked.
  def handle(data)
    OrderPaymentClaim.new(order: Order.find(data["order_id"]), payment_id: data["id"]).call
  end
end
