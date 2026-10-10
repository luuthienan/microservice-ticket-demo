# A local copy of an order owned by the orders service.
class Order < ApplicationRecord
  enum :status, { awaiting_payment: "awaiting_payment", cancelled: "cancelled", complete: "complete" }

  has_one :payment
end
