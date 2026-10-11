class Payment < ApplicationRecord
  # Pending until the card is charged for the order it claimed, then paid, or failed (declined, or the order was cancelled).
  enum :status, { pending: "pending", paid: "paid", failed: "failed" }

  belongs_to :order
end
