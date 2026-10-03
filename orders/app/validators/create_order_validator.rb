class CreateOrderValidator
  include ActiveModel::Model

  attr_accessor :ticket_id

  validates :ticket_id, presence: true
end
