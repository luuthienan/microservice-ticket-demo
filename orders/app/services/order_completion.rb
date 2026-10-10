class OrderCompletion
  include ActiveModel::Model

  attr_accessor :order

  # Returns the order, or false with errors when it was cancelled in the meantime.
  def call
    if order.cancelled?
      errors.add(:base, "Order is cancelled")
      return false
    end

    ApplicationRecord.transaction do
      order.update!(status: :complete)
      EventPublisher.new.publish("order:completed", event_data) if order.saved_changes?
    end
    order
  end

  private

  def event_data
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id, ticket: { id: order.ticket_id } }
  end
end
