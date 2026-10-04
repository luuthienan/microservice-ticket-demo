class OrderCreation
  include ActiveModel::Model

  EXPIRATION_WINDOW = 15.minutes

  attr_accessor :ticket_id, :user_id

  # Returns the new order, or false with errors when the ticket is already reserved.
  def call
    ticket = Ticket.find(ticket_id)
    if ticket.reserved?
      errors.add(:base, "Ticket is already reserved")
      return false
    end

    order = ApplicationRecord.transaction do
      order = Order.create!(user_id:, ticket:, expires_at: EXPIRATION_WINDOW.from_now)
      EventPublisher.new.publish("order:created", event_data(order))
      order
    end
    ExpireOrderJob.perform_at(order.expires_at, order.id)
    order
  end

  private

  def event_data(order)
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id,
      expires_at: order.expires_at.iso8601, ticket: { id: order.ticket_id, price: order.ticket.price } }
  end
end
