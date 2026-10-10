class TicketUpdatedListener
  def self.subject = "ticket:updated"

  def handle(data)
    TicketCopyUpdate.new(data.slice("id", "title", "price", "status", "version")).call
  end
end
