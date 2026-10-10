class TicketCreation
  include ActiveModel::Model

  attr_accessor :title, :price, :user_id

  def call
    ApplicationRecord.transaction do
      ticket = Ticket.create!(title:, price:, user_id:)
      EventPublisher.new.publish("ticket:created", event_data(ticket))
      ticket
    end
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, status: ticket.status, version: ticket.lock_version }
  end
end
