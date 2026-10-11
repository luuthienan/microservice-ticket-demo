class OrderCompletion
  include ActiveModel::Model

  attr_accessor :order, :payment_id

  # Returns the order, or false with errors when it was cancelled in the meantime or is not claimed for this payment.
  def call
    return order if order.complete?

    if order.cancelled?
      errors.add(:base, "Order is cancelled")
      return false
    end
    unless order.payment_processing? && order.payment_id == payment_id
      errors.add(:base, "Order is not processing this payment")
      return false
    end

    ApplicationRecord.transaction do
      order.update!(status: :complete)
      EventPublisher.new.publish("order:completed", event_data)
    end
    order
  end

  private

  def event_data
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id, ticket: { id: order.ticket_id } }
  end
end
