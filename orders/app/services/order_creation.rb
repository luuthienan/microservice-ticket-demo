class OrderCreation
  include ActiveModel::Model

  DEFAULT_EXPIRATION_WINDOW_SECONDS = 60

  attr_accessor :ticket_id, :user_id

  ACTIVE_ORDER_INDEX = "index_orders_on_ticket_id_active"

  # Returns the new order, or false with errors when the ticket is already reserved or otherwise not available.
  # The checks below read the Copy, which can lag behind the tickets service, so they are a fast path;
  # the unique index on active orders is what decides a race.
  def call
    ticket = Ticket.find(ticket_id)
    return already_reserved if ticket.reserved?
    return not_available unless ticket.available?

    order = ApplicationRecord.transaction do
      order = Order.create!(user_id:, ticket:, expires_at: expiration_window.from_now)
      EventPublisher.new.publish("order:created", event_data(order))
      order
    end
    ExpireOrderJob.perform_at(order.expires_at, order.id)
    order
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

  # How long an unpaid order lasts, from EXPIRATION_WINDOW_SECONDS (default 60).
  def expiration_window
    raw = ENV.fetch("EXPIRATION_WINDOW_SECONDS", DEFAULT_EXPIRATION_WINDOW_SECONDS)
    seconds = Integer(raw, exception: false)
    raise ArgumentError, "EXPIRATION_WINDOW_SECONDS must be a positive integer, got #{raw.inspect}" unless seconds&.positive?

    seconds.seconds
  end

  def event_data(order)
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id,
      expires_at: order.expires_at.iso8601, ticket: { id: order.ticket_id, price: order.ticket.price } }
  end
end
