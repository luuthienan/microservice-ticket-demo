# Locks the ticket by recording which order holds it.
class OrderCreatedListener
  def self.subject = "order:created"

  def handle(data)
    ticket = Ticket.find(data["ticket"]["id"])
    ticket.update!(order_id: data["id"])
    ticket.publish_updated
  end
end
