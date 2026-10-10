class OrderAwaitingPaymentListener
  def self.subject = "order:awaiting_payment"

  # The order Copy exists only from here, so an order that is still Pending (or was rejected) can't be paid.
  # The price is the one of the ticket version that was reserved.
  def handle(data)
    OrderCopyCreation.new(
      id: data["id"], user_id: data["user_id"], status: data["status"],
      price: data["ticket"]["price"], version: data["version"]
    ).call
  end
end
