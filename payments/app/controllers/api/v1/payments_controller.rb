class Api::V1::PaymentsController < ApplicationController
  before_action :require_auth

  def create
    validator = CreatePaymentValidator.new(order_id: params[:orderId], token: params[:token])
    return render_validation_errors(validator) unless validator.valid?

    service = PaymentCreation.new(order_id: validator.order_id, token: validator.token, user_id: current_user["id"])
    payment = service.call
    return render_validation_errors(service) unless payment

    render json: { id: payment.id }, status: :created
  end
end
