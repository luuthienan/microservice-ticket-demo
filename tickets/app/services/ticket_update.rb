class TicketUpdate
  include ActiveModel::Model

  # attributes holds only the fields present in the request (title and/or price).
  attr_accessor :ticket_id, :user_id, :attributes

  # Returns the ticket, or false with errors when it is no longer available (reserved, sold or cancelled).
  def call
    ticket = Ticket.find(ticket_id)
    raise ApiError::NotAuthorized unless ticket.user_id == user_id

    unless ticket.available?
      errors.add(:base, "Cannot edit a #{ticket.status} ticket")
      return false
    end

    ApplicationRecord.transaction do
      ticket.update!(attributes)
      EventPublisher.new.publish("ticket:updated", event_data(ticket)) if ticket.saved_changes?
    end
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, status: ticket.status, version: ticket.lock_version }
  end
end
