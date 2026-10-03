class Api::V1::OrdersController < ApplicationController
  EXPIRATION_WINDOW = 15.minutes

  before_action :require_auth

  def index
    render json: Order.where(user_id: current_user["id"]).includes(:ticket)
  end

  def show
    render json: find_order
  end

  def create
    ticket = Ticket.find(params[:ticketId])
    raise ApiError, "Ticket is already reserved" if ticket.reserved?

    order = Order.create!(user_id: current_user["id"], ticket:, expires_at: EXPIRATION_WINDOW.from_now)
    Events.publish("order:created", order.event_data)
    render json: order, status: :created
  end

  def destroy
    find_order.cancel!
    head :no_content
  end

  private

  def find_order
    order = Order.find(params[:id])
    raise ApiError::NotAuthorized unless order.user_id == current_user["id"]

    order
  end
end
