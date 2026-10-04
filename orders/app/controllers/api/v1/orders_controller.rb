class Api::V1::OrdersController < ApplicationController
  before_action :require_auth

  def index
    render json: Order.where(user_id: current_user["id"]).includes(:ticket).order(created_at: :desc, id: :desc)
  end

  def show
    order = Order.find(params[:id])
    raise ApiError::NotAuthorized unless order.user_id == current_user["id"]

    render json: order
  end

  def create
    validator = CreateOrderValidator.new(ticket_id: params[:ticket_id])
    return render_validation_errors(validator) unless validator.valid?

    service = OrderCreation.new(ticket_id: validator.ticket_id, user_id: current_user["id"])
    order = service.call
    return render_validation_errors(service) unless order

    render json: order, status: :created
  end

  def destroy
    service = OrderCancellation.new(order: Order.find(params[:id]), user_id: current_user["id"])
    return render_validation_errors(service) unless service.call

    head :no_content
  end
end
