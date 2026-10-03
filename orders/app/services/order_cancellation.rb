class OrderCancellation
  include ActiveModel::Model

  # user_id is the requesting user; leave it nil for system-initiated cancellations (e.g. expiry).
  attr_accessor :order, :user_id

  # Returns the order, or false with errors when it is no longer cancellable.
  def call
    raise ApiError::NotAuthorized if user_id && order.user_id != user_id

    unless order.created?
      errors.add(:base, "Order cannot be cancelled")
      return false
    end

    order.update!(status: :cancelled)
    Events.publish("order:cancelled", { id: order.id, version: order.lock_version, ticket: { id: order.ticket_id } })
    order
  end
end
