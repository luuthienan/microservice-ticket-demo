class CreatePaymentValidator
  include ActiveModel::Model

  attr_accessor :order_id, :token

  validates :order_id, :token, presence: true
end
