# Moves a Pending order to awaiting payment once the tickets service has reserved its ticket: starts the
# payment deadline and tells payments the order can be paid. An order that was cancelled in the meantime
# stays cancelled (tickets releases the ticket when it sees order:cancelled). Safe to run twice.
class OrderConfirmation
  include ActiveModel::Model

  DEFAULT_EXPIRATION_WINDOW_SECONDS = 60

  attr_accessor :order

  def call
    confirm if order.created?
    # Also on a replay, so a job lost after the commit is scheduled again; an extra job finds the order settled.
    ExpireOrderJob.perform_at(order.expires_at, order.id) if order.awaiting_payment?
    order
  end

  private

  def confirm
    ApplicationRecord.transaction do
      order.update!(status: :awaiting_payment, expires_at: expiration_window.from_now)
      EventPublisher.new.publish("order:awaiting_payment", event_data)
    end
  end

  # How long an unpaid order lasts, from EXPIRATION_WINDOW_SECONDS (default 60).
  def expiration_window
    raw = ENV.fetch("EXPIRATION_WINDOW_SECONDS", DEFAULT_EXPIRATION_WINDOW_SECONDS)
    seconds = Integer(raw, exception: false)
    raise ArgumentError, "EXPIRATION_WINDOW_SECONDS must be a positive integer, got #{raw.inspect}" unless seconds&.positive?

    seconds.seconds
  end

  def event_data
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id,
      expires_at: order.expires_at.iso8601, ticket: { id: order.ticket_id, price: order.ticket.price } }
  end
end
