# Puts an order back to awaiting payment when the payment it was claimed for failed, keeping its deadline, and tells
# payments it can be paid again. Expiry skipped the order while it was claimed, so it is scheduled again; a deadline
# that has passed runs at once. A payment other than the one the order is claimed for (a replayed event) changes
# nothing. Safe to run twice.
class OrderPaymentRelease
  include ActiveModel::Model

  attr_accessor :order, :payment_id

  def call
    release if order.payment_processing? && order.payment_id == payment_id
    # Also on a replay, so a job lost after the commit is scheduled again; an extra job finds the order settled.
    ExpireOrderJob.perform_at(order.expires_at, order.id) if order.awaiting_payment? && order.payment_id == payment_id
    order
  end

  private

  def release
    ApplicationRecord.transaction do
      order.update!(status: :awaiting_payment)
      EventPublisher.new.publish("order:awaiting_payment", event_data)
    end
  end

  def event_data
    { id: order.id, version: order.lock_version, status: order.status, user_id: order.user_id,
      expires_at: order.expires_at.iso8601, ticket: { id: order.ticket_id, price: order.ticket.price } }
  end
end
