# Claims an order awaiting payment for a payment, so payments may charge for it and expiry leaves it alone.
# The order's lock_version decides between a claim and an expiry or cancel that run at the same time: the loser
# raises, is retried, and finds the order settled. A payment older than the one the order was last claimed for
# (a replayed event), or an order that is no longer awaiting payment, is left as it is. Safe to run twice.
class OrderPaymentClaim
  include ActiveModel::Model

  attr_accessor :order, :payment_id

  def call
    claim if claimable?
    order
  end

  private

  def claimable?
    order.awaiting_payment? && (order.payment_id.nil? || payment_id > order.payment_id)
  end

  def claim
    ApplicationRecord.transaction do
      order.update!(status: :payment_processing, payment_id:)
      EventPublisher.new.publish("order:payment_processing", event_data)
    end
  end

  def event_data
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id, payment_id:,
      ticket: { id: order.ticket_id } }
  end
end
