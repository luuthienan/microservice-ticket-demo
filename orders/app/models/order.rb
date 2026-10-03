class Order < ApplicationRecord
  enum :status, { created: "created", cancelled: "cancelled", complete: "complete" }

  belongs_to :ticket
end
