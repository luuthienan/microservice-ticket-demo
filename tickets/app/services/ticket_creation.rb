class TicketCreation
  include ActiveModel::Model

  attr_accessor :title, :price, :user_id

  def call
    ticket = Ticket.create!(title:, price:, user_id:)
    Events.publish("ticket:created", event_data(ticket))
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, version: ticket.lock_version }
  end
end
