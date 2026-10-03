# A local copy of a ticket owned by the tickets service.
class Ticket < ApplicationRecord
  has_many :orders

  def reserved?
    orders.where.not(status: :cancelled).exists?
  end
end
