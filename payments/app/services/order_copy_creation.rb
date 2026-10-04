# Stores a local copy of an order owned by the orders service. A copy that already exists is kept as is.
class OrderCopyCreation
  include ActiveModel::Model

  attr_accessor :id, :user_id, :status, :price, :version

  def call
    Order.find_or_create_by!(id:) { |order| order.assign_attributes(user_id:, status:, price:, version:) }
  end
end
