class TicketCreatedListener
  def self.subject = "ticket:created"

  def handle(data)
    TicketCopyCreation.new(data.slice("id", "title", "price", "version")).call
  end
end
