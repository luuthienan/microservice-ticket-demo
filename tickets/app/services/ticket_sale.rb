# Marks the ticket sold once the order that holds it is paid for. An order that doesn't hold the
# ticket (it was released, or a newer order holds it) is ignored, so a replayed order:completed is harmless.
class TicketSale
  include ActiveModel::Model

  attr_accessor :ticket_id, :order_id

  def call
    ticket = Ticket.find(ticket_id)
    unless ticket.reserved? && ticket.order_id == order_id
      Rails.logger.info("Ignoring order:completed for order #{order_id}: ticket #{ticket.id} is #{ticket.status} (order #{ticket.order_id.inspect})")
      return ticket
    end

    ApplicationRecord.transaction do
      ticket.update!(status: :sold)
      EventPublisher.new.publish("ticket:updated", event_data(ticket)) if ticket.saved_changes?
    end
    ticket
  end

  private

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, status: ticket.status, version: ticket.lock_version }
  end
end
