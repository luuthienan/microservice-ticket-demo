# Locks the ticket by recording which order holds it.
class TicketReservation
  include ActiveModel::Model

  attr_accessor :ticket_id, :order_id

  def call
    ticket = Ticket.find(ticket_id)
    ticket.update!(order_id:)
    EventPublisher.new.publish("ticket:updated", event_data(ticket)) if ticket.saved_changes?
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, version: ticket.lock_version }
  end
end
