# Applies updates strictly in order: an event for version N only matches a copy at version N - 1.
# Otherwise it raises, stays unacked, and is redelivered after the missing update arrives.
class TicketUpdatedListener
  def self.subject = "ticket:updated"

  def handle(data)
    ticket = Ticket.find_by!(id: data["id"], version: data["version"] - 1)
    ticket.update!(title: data["title"], price: data["price"], version: data["version"])
  end
end
