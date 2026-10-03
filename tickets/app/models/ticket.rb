class Ticket < ApplicationRecord
  def reserved? = order_id.present?
end
