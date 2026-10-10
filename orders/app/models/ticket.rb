# A local copy of a ticket owned by the tickets service.
class Ticket < ApplicationRecord
  has_many :orders

  # The owning service's view of the ticket. It can lag behind the orders here, so reserved? looks at those.
  def available? = status == "available"

  def reserved?
    orders.where.not(status: :cancelled).exists?
  end
end
