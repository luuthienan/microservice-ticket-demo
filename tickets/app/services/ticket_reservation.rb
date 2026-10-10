# Reserves the ticket for the order that holds it, provided the ticket is still the one the order was
# placed from: Available, and at the Version the order recorded. The Version is checked by the same
# UPDATE that reserves (optimistic lock), so a seller's edit and a reservation can't both win. Whichever
# way it fails, orders is told with ticket:reservation-rejected so it can cancel the order.
# A replayed order:created for a ticket the order already holds is left alone.
class TicketReservation
  include ActiveModel::Model

  attr_accessor :ticket_id, :order_id, :version

  def call
    ticket = Ticket.find(ticket_id)
    return ticket if held_by_order?(ticket)
    return reject(ticket, :unavailable) unless ticket.available?
    return reject(ticket, :stale_version) unless ticket.lock_version == version

    ApplicationRecord.transaction do
      ticket.update!(status: :reserved, order_id:)
      EventPublisher.new.publish("ticket:reserved", event_data(ticket))
    end
    ticket
  rescue ActiveRecord::StaleObjectError
    reject(ticket, :stale_version)
  end

  private

  def held_by_order?(ticket)
    (ticket.reserved? || ticket.sold?) && ticket.order_id == order_id
  end

  def reject(ticket, reason)
    ApplicationRecord.transaction do
      EventPublisher.new.publish("ticket:reservation-rejected", { id: ticket.id, order_id:, reason: })
    end
    ticket
  end

  def event_data(ticket)
    { id: ticket.id, title: ticket.title, price: ticket.price, user_id: ticket.user_id,
      order_id: ticket.order_id, status: ticket.status, version: ticket.lock_version }
  end
end
