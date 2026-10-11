class Order < ApplicationRecord
  # "created" is a Pending order: its ticket is not yet confirmed as reserved, so it has no expires_at.
  # "payment_processing" is an order claimed for a payment: payments charges only once orders has made the claim,
  # and expiry and the buyer's cancel leave a claimed order alone, so a charge never meets a cancelled order.
  enum :status, { created: "created", awaiting_payment: "awaiting_payment", payment_processing: "payment_processing",
                  cancelled: "cancelled", complete: "complete" }

  belongs_to :ticket
end
