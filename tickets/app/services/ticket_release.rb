# Unlocks the ticket, but only for the order that holds it, so a replayed cancellation can't
# release the ticket from a newer order.
class TicketRelease
  include ActiveModel::Model

  attr_accessor :ticket_id, :order_id

  def call
    ticket = Ticket.find(ticket_id)
    return ticket unless ticket.order_id == order_id

    ApplicationRecord.transaction do
      ticket.update!(order_id: nil)
      EventPublisher.new.publish("ticket:updated", event_data(ticket)) if ticket.saved_changes?
    end
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, version: ticket.lock_version }
  end
end
