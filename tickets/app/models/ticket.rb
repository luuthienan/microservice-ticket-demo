class Ticket < ApplicationRecord
  def reserved? = order_id.present?

  def as_json(*)
    { id:, title:, price: price.to_f, userId: user_id, orderId: order_id, version: lock_version }
  end
end
