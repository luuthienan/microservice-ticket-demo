class Api::V1::PaymentsController < ApplicationController
  before_action :require_auth

  def create
    order = Order.find(params[:orderId])
    raise ApiError::NotAuthorized unless order.user_id == current_user["id"]
    raise ApiError, "Cannot pay for a cancelled order" if order.cancelled?
    raise ApiError, "Order is already paid" if order.payment

    charge = Stripe::Charge.create(
      amount: (order.price * 100).to_i,
      currency: "usd",
      source: params[:token],
      description: "Order #{order.id}"
    )
    payment = Payment.create!(order:, stripe_id: charge.id)
    Events.publish("payment:created", { id: payment.id, order_id: order.id, stripe_id: payment.stripe_id })

    render json: { id: payment.id }, status: :created
  end
end
