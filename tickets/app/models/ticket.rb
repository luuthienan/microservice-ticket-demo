class Ticket < ApplicationRecord
  enum :status, { available: "available", reserved: "reserved", sold: "sold", cancelled: "cancelled" }
end
