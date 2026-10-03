class TicketUpdate
  include ActiveModel::Model

  # attributes holds only the fields present in the request (title and/or price).
  attr_accessor :ticket_id, :user_id, :attributes

  # Returns the ticket, or false with errors when it is reserved by an order.
  def call
    ticket = Ticket.find(ticket_id)
    raise ApiError::NotAuthorized unless ticket.user_id == user_id

    if ticket.reserved?
      errors.add(:base, "Cannot edit a reserved ticket")
      return false
    end

    ticket.update!(attributes)
    Events.publish("ticket:updated", event_data(ticket)) if ticket.saved_changes?
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, version: ticket.lock_version }
  end
end
