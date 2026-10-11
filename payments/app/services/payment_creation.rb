# Records that the buyer wants to pay for an order and asks orders to claim it (payment:requested). The card is
# charged only once orders has claimed the order (order:payment_processing), see PaymentCharge, so a payment never
# races the order's expiry.
class PaymentCreation
  include ActiveModel::Model

  attr_accessor :order_id, :token, :user_id

  # Returns the pending payment, or false with errors when the order can no longer be paid, is still Pending
  # (the tickets service has not yet confirmed its ticket) or already has a payment that did not fail.
  def call
    order = Order.find(order_id)
    raise ApiError::NotAuthorized unless order.user_id == user_id

    # Locking the copy makes this check and the order's cancellation (OrderCopyCancellation) take turns, so a
    # payment is never left pending on an order cancelled just before it.
    ApplicationRecord.transaction do
      order.lock!
      refusal = refusal_for(order)
      if refusal
        errors.add(:base, refusal)
        false
      else
        request_payment(order)
      end
    end
  end

  private

  def refusal_for(order)
    return "Cannot pay for a cancelled order" if order.cancelled?
    return "Order is already paid" if order.payments.paid.exists?
    return "A payment is already in progress" if order.payments.pending.exists?

    # A copy still claimed after its payment failed is about to hear that the order can be paid again.
    "Order is not awaiting payment" unless order.awaiting_payment? || order.payment_processing?
  end

  def request_payment(order)
    payment = Payment.create!(order:, token:)
    EventPublisher.new.publish("payment:requested", { id: payment.id, order_id: order.id })
    payment
  end
end
