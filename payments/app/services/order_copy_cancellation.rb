# Applies updates strictly in order: an event for version N only matches a copy at version N - 1.
# Otherwise it raises, stays unacked, and is redelivered.
class OrderCopyCancellation
  include ActiveModel::Model

  attr_accessor :id, :version

  def call
    order = Order.find_by!(id:, version: version - 1)
    order.update!(status: :cancelled, version:)
    order
  end
end
