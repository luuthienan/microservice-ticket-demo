class Api::V1::PaymentsController < ApplicationController
  before_action :require_auth

  def create
    validator = CreatePaymentValidator.new(order_id: params[:order_id], token: params[:token])
    return render_validation_errors(validator) unless validator.valid?

    service = PaymentCreation.new(order_id: validator.order_id, token: validator.token, user_id: current_user["id"])
    payment = service.call
    return render_validation_errors(service) unless payment

    render json: { id: payment.id }, status: :created
  end

  # Where a buyer follows a payment: pending, then paid, or failed with the reason.
  def show
    payment = Payment.find(params[:id])
    raise ApiError::NotAuthorized unless payment.order.user_id == current_user["id"]

    render json: { id: payment.id, status: payment.status, failure_message: payment.failure_message }
  end
end
