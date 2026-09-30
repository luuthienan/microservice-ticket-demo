class TicketCreatedListener
  def self.subject = "ticket:created"

  def handle(data)
    Ticket.create!(id: data["id"], title: data["title"], price: data["price"], version: data["version"])
  end
end
