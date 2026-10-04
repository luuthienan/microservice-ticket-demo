class OrderCancelledListener
  def self.subject = "order:cancelled"

  def handle(data)
    TicketRelease.new(ticket_id: data["ticket"]["id"], order_id: data["id"]).call
  end
end
