class OrderCompletion
  include ActiveModel::Model

  attr_accessor :order

  def call
    order.update!(status: :complete)
    order
  end
end
