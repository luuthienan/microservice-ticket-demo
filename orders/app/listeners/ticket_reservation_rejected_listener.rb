class TicketReservationRejectedListener
  def self.subject = "ticket:reservation-rejected"

  # The tickets service could not reserve the ticket for the order, so the order is cancelled. An order that
  # is no longer cancellable (already cancelled, or paid) is a no-op, so the event is still acked.
  def handle(data)
    order = Order.find_by(id: data["order_id"])
    OrderCancellation.new(order:).call if order
  end
end
