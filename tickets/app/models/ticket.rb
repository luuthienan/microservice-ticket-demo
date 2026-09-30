class Ticket < ApplicationRecord
  validates :title, presence: true
  validates :price, numericality: { greater_than: 0 }

  def reserved? = order_id.present?

  def publish_updated
    Events.publish("ticket:updated", event_data) if saved_changes?
  end

  def event_data
    { id:, title:, price:, user_id:, order_id:, version: lock_version }
  end

  def as_json(*)
    { id:, title:, price: price.to_f, userId: user_id, orderId: order_id, version: lock_version }
  end
end
