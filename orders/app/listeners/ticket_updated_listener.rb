class TicketUpdatedListener
  def self.subject = "ticket:updated"

  def handle(data)
    TicketCopyUpdate.new(data.slice("id", "title", "price", "version")).call
  end
end
