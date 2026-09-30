class ExpirationCompleteListener
  def self.subject = "expiration:complete"

  def handle(data)
    order = Order.find(data["order_id"])
    order.cancel! if order.created?
  end
end
