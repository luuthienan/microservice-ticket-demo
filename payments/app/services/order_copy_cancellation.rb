# Applies updates strictly in order: an event for version N only applies to a copy at version N - 1.
# An update the copy already has (a replay or a duplicate) is ignored. A gap raises, so the event is
# retried until the missing update arrives, then dead-lettered. A payment still waiting for the order
# to be claimed can no longer be: it fails, with nothing to charge and no event, as the order is cancelled.
class OrderCopyCancellation
  include ActiveModel::Model

  attr_accessor :id, :version

  def call
    order = Order.find(id)
    return order if version <= order.version

    # Locks the copy, as PaymentCreation does, so a payment requested at the same moment is not missed.
    ApplicationRecord.transaction do
      order = Order.lock.find_by!(id:, version: version - 1)
      order.update!(status: :cancelled, version:)
      order.payments.pending.update_all(status: "failed", failure_message: "Order was cancelled", updated_at: Time.current)
    end
    order
  end
end
