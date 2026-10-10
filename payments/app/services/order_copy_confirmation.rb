# Applies updates strictly in order: an event for version N only applies to a copy at version N - 1.
# An update the copy already has (a replay or a duplicate) is ignored. A gap raises, so the event is
# retried until the missing update arrives, then dead-lettered. The copy takes the price of the ticket
# version that was reserved, which is the one to charge.
class OrderCopyConfirmation
  include ActiveModel::Model

  attr_accessor :id, :price, :version

  def call
    order = Order.find(id)
    return order if version <= order.version

    order = Order.find_by!(id:, version: version - 1)
    order.update!(status: :awaiting_payment, price:, version:)
    order
  end
end
