class OrderPaymentProcessingListener
  def self.subject = "order:payment_processing"

  # Orders has claimed the order for the payment, so the card may now be charged. The charge is for the payment the
  # event names, and does nothing if that payment is no longer pending, as when the event is replayed.
  def handle(data)
    OrderCopyPaymentProcessing.new(data.slice("id", "version")).call
    PaymentCharge.new(payment_id: data["payment_id"]).call
  end
end
