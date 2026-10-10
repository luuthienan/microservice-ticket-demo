# Applies updates strictly in order: an event for version N only applies to a copy at version N - 1.
# An update the copy already has (a replay or a duplicate) is ignored. A gap raises, so the event is
# retried until the missing update arrives, then dead-lettered. An order with no copy was cancelled
# while Pending, before it could be paid, so there is nothing to cancel.
class OrderCopyCancellation
  include ActiveModel::Model

  attr_accessor :id, :version

  def call
    order = Order.find_by(id:)
    return unless order
    return order if version <= order.version

    order = Order.find_by!(id:, version: version - 1)
    order.update!(status: :cancelled, version:)
    order
  end
end
