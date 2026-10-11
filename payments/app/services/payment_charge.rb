# Charges the card of a payment once orders has claimed its order. A card that is declined, or a token Stripe
# refuses, fails the payment for good (payment:failed); anything else (Stripe unreachable) is raised, so the event is
# retried, which is safe because the charge carries an idempotency key. A payment that is no longer pending
# (a replayed event) is left as it is.
class PaymentCharge
  include ActiveModel::Model

  attr_accessor :payment_id

  def call
    payment = Payment.find(payment_id)
    return payment unless payment.pending?

    charge = Stripe::Charge.create(
      { amount: (payment.order.price * 100).to_i, currency: "usd", source: payment.token, description: "Order #{payment.order_id}" },
      { idempotency_key: "payment-#{payment.order_id}-#{payment.id}" }
    )
    settle(payment, status: :paid, stripe_id: charge.id)
  rescue Stripe::CardError, Stripe::InvalidRequestError => e
    settle(payment, status: :failed, failure_message: e.message)
  end

  private

  def settle(payment, **attributes)
    ApplicationRecord.transaction do
      payment.update!(attributes)
      EventPublisher.new.publish("payment:#{payment.status}", event_data(payment))
    end
    payment
  end

  def event_data(payment)
    { id: payment.id, order_id: payment.order_id }.tap { |data| data[:stripe_id] = payment.stripe_id if payment.paid? }
  end
end
