class Api::V1::TicketsController < ApplicationController
  before_action :require_auth, only: %i[mine create update]

  def index
    render json: Ticket.all
  end

  def mine
    render json: Ticket.where(user_id: current_user["id"]).order(created_at: :desc, id: :desc)
  end

  def show
    render json: Ticket.find(params[:id])
  end

  def create
    validator = CreateTicketValidator.new(ticket_params)
    return render_validation_errors(validator) unless validator.valid?

    ticket = TicketCreation.new(title: validator.title, price: validator.price, user_id: current_user["id"]).call
    render json: ticket, status: :created
  end

  def update
    validator = UpdateTicketValidator.new(ticket_params)
    return render_validation_errors(validator) unless validator.valid?

    service = TicketUpdate.new(ticket_id: params[:id], user_id: current_user["id"], attributes: ticket_params.to_h)
    ticket = service.call
    return render_validation_errors(service) unless ticket

    render json: ticket
  end

  private

  def ticket_params
    params.permit(:title, :price)
  end
end
