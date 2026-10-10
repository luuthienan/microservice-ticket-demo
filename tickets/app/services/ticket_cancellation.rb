class TicketCancellation
  include ActiveModel::Model

  attr_accessor :ticket_id, :user_id

  # Returns the ticket, or false with errors when it is no longer available (reserved, sold or already cancelled).
  def call
    ticket = Ticket.find(ticket_id)
    raise ApiError::NotAuthorized unless ticket.user_id == user_id

    unless ticket.available?
      errors.add(:base, "Cannot cancel a #{ticket.status} ticket")
      return false
    end

    ApplicationRecord.transaction do
      ticket.update!(status: :cancelled)
      EventPublisher.new.publish("ticket:updated", event_data(ticket))
    end
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, status: ticket.status, version: ticket.lock_version }
  end
end
