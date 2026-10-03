class ExpirationCompleteListener
  def self.subject = "expiration:complete"

  def handle(data)
    order = Order.find(data["order_id"])
    OrderCancellation.new(order:).call if order.created?
  end
end
