# Applies updates strictly in order: an event for version N only applies to a copy at version N - 1.
# An update the copy already has (a replay or a duplicate) is ignored. A gap raises, so the event is
# retried until the missing update arrives, then dead-lettered. The copy follows the order into payment
# processing: a payment has claimed it and the card may be charged.
class OrderCopyPaymentProcessing
  include ActiveModel::Model

  attr_accessor :id, :version

  def call
    order = Order.find(id)
    return order if version <= order.version

    order = Order.find_by!(id:, version: version - 1)
    order.update!(status: :payment_processing, version:)
    order
  end
end
