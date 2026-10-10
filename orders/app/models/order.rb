class Order < ApplicationRecord
  # "created" is a Pending order: its ticket is not yet confirmed as reserved, so it has no expires_at.
  enum :status, { created: "created", awaiting_payment: "awaiting_payment", cancelled: "cancelled", complete: "complete" }

  belongs_to :ticket
end
