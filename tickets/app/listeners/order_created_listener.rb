class OrderCreatedListener
  def self.subject = "order:created"

  def handle(data)
    TicketReservation.new(ticket_id: data["ticket"]["id"], order_id: data["id"], version: data["ticket"]["version"]).call
  end
end
