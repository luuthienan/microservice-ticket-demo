class OrderCreation
  include ActiveModel::Model

  attr_accessor :ticket_id, :user_id

  ACTIVE_ORDER_INDEX = "index_orders_on_ticket_id_active"

  # Returns the new Pending order, or false with errors when the ticket is already reserved or otherwise not available.
  # The order records the Version of the ticket Copy it was placed from, so the tickets service can reject it if
  # the ticket changed since. It has no deadline until the tickets service confirms the reservation (OrderConfirmation).
  # The checks below read the Copy, which can lag behind the tickets service, so they are a fast path;
  # the unique index on active orders is what decides a race.
  def call
    ticket = Ticket.find(ticket_id)
    return already_reserved if ticket.reserved?
    return not_available unless ticket.available?

    order = ApplicationRecord.transaction do
      order = Order.create!(user_id:, ticket:)
      EventPublisher.new.publish("order:created", event_data(order))
      order
    end
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?(ACTIVE_ORDER_INDEX)

    already_reserved
  end

  private

  def already_reserved
    errors.add(:base, "Ticket is already reserved")
    false
  end

  def not_available
    errors.add(:base, "Ticket is not available")
    false
  end

  def event_data(order)
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id,
      ticket: { id: order.ticket_id, price: order.ticket.price, version: order.ticket.version } }
  end
end
