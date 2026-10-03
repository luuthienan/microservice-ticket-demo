class TicketSerializer < ActiveModel::Serializer
  attributes :id, :title, :price, :user_id, :order_id, :version

  def price = format("%.2f", object.price)

  def version = object.lock_version
end
