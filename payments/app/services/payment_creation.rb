class PaymentCreation
  include ActiveModel::Model

  attr_accessor :order_id, :token, :user_id

  # Returns the payment, or false with errors when the order can no longer be paid. There is no order to pay
  # (404) until the tickets service has confirmed its ticket and the order is awaiting payment.
  def call
    order = Order.find(order_id)
    raise ApiError::NotAuthorized unless order.user_id == user_id

    if order.cancelled?
      errors.add(:base, "Cannot pay for a cancelled order")
      return false
    end
    if order.payment
      errors.add(:base, "Order is already paid")
      return false
    end
    unless order.awaiting_payment?
      errors.add(:base, "Order is not awaiting payment")
      return false
    end

    charge = Stripe::Charge.create(
      amount: (order.price * 100).to_i,
      currency: "usd",
      source: token,
      description: "Order #{order.id}"
    )
    ApplicationRecord.transaction do
      payment = Payment.create!(order:, stripe_id: charge.id)
      EventPublisher.new.publish("payment:created", { id: payment.id, order_id: order.id, stripe_id: payment.stripe_id })
      payment
    end
  end
end
