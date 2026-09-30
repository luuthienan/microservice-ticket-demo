# Unlocks the ticket.
class OrderCancelledListener
  def self.subject = "order:cancelled"

  def handle(data)
    ticket = Ticket.find(data["ticket"]["id"])
    ticket.update!(order_id: nil)
    ticket.publish_updated
  end
end
