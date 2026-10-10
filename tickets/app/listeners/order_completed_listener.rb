class OrderCompletedListener
  def self.subject = "order:completed"

  def handle(data)
    TicketSale.new(ticket_id: data["ticket"]["id"], order_id: data["id"]).call
  end
end
