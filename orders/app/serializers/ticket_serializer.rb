class TicketSerializer < ActiveModel::Serializer
  attributes :id, :title, :price

  def price = format("%.2f", object.price)
end
