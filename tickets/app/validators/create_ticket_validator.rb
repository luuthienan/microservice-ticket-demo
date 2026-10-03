class CreateTicketValidator
  include ActiveModel::Model

  attr_accessor :title, :price

  validates :title, presence: true
  validates :price, numericality: { greater_than: 0 }
end
