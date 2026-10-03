class OrderCancelledListener
  def self.subject = "order:cancelled"

  def handle(data)
    TicketRelease.new(ticket_id: data["ticket"]["id"]).call
  end
end
