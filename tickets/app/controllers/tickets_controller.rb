class TicketsController < ApplicationController
  before_action :require_auth, only: %i[create update]

  def index
    render json: Ticket.all
  end

  def show
    render json: Ticket.find(params[:id])
  end

  def create
    ticket = Ticket.create!(ticket_params.merge(user_id: current_user["id"]))
    Events.publish("ticket:created", ticket.event_data)
    render json: ticket, status: :created
  end

  def update
    ticket = Ticket.find(params[:id])
    raise ApiError::NotAuthorized unless ticket.user_id == current_user["id"]
    raise ApiError, "Cannot edit a reserved ticket" if ticket.reserved?

    ticket.update!(ticket_params)
    ticket.publish_updated
    render json: ticket
  end

  private

  def ticket_params
    params.permit(:title, :price)
  end
end
