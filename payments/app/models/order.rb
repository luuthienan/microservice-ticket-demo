# A local copy of an order owned by the orders service.
class Order < ApplicationRecord
  enum :status, { created: "created", awaiting_payment: "awaiting_payment", payment_processing: "payment_processing",
                  cancelled: "cancelled", complete: "complete" }

  has_many :payments
end
