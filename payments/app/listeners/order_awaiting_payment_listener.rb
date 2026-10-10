class OrderAwaitingPaymentListener
  def self.subject = "order:awaiting_payment"

  # Only from here can the order be paid. The price is the one of the ticket version that was reserved,
  # which may differ from the one the order was placed at.
  def handle(data)
    OrderCopyConfirmation.new(id: data["id"], price: data["ticket"]["price"], version: data["version"]).call
  end
end
