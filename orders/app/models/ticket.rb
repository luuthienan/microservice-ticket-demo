# A local copy of a ticket owned by the tickets service.
class Ticket < ApplicationRecord
  enum :status, { available: "available", reserved: "reserved", sold: "sold", cancelled: "cancelled" }

  has_many :orders
end
