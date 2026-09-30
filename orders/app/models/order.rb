class Order < ApplicationRecord
  enum :status, { created: "created", cancelled: "cancelled", complete: "complete" }

  belongs_to :ticket

  def cancel!
    update!(status: :cancelled)
    Events.publish("order:cancelled", { id:, version: lock_version, ticket: { id: ticket_id } })
  end

  def event_data
    { id:, version: lock_version, status:, user_id:, expires_at: expires_at.iso8601,
      ticket: { id: ticket_id, price: ticket.price } }
  end

  def as_json(*)
    { id:, status:, userId: user_id, expiresAt: expires_at, version: lock_version, ticket: }
  end
end
