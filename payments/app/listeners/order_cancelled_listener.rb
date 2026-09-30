# Applies updates strictly in order: an event for version N only matches a copy at version N - 1.
# Otherwise it raises, stays unacked, and is redelivered.
class OrderCancelledListener
  def self.subject = "order:cancelled"

  def handle(data)
    order = Order.find_by!(id: data["id"], version: data["version"] - 1)
    order.update!(status: :cancelled, version: data["version"])
  end
end
