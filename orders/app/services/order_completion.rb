class OrderCompletion
  include ActiveModel::Model

  attr_accessor :order

  # Returns the order, or false with errors when it was cancelled in the meantime.
  def call
    if order.cancelled?
      errors.add(:base, "Order is cancelled")
      return false
    end

    order.update!(status: :complete)
    order
  end
end
