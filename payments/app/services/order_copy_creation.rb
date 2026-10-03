# Stores a local copy of an order owned by the orders service.
class OrderCopyCreation
  include ActiveModel::Model

  attr_accessor :id, :user_id, :status, :price, :version

  def call
    Order.create!(id:, user_id:, status:, price:, version:)
  end
end
