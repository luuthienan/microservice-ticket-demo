class TicketReservedListener
  def self.subject = "ticket:reserved"

  # The ticket Copy follows the reservation like any other update, then the order that holds it is confirmed.
  # An order that is no longer Pending is left as it is.
  def handle(data)
    TicketCopyUpdate.new(data.slice("id", "title", "price", "status", "version")).call
    order = Order.find_by(id: data["order_id"])
    OrderConfirmation.new(order:).call if order
  end
end
