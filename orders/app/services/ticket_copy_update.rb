# Applies updates strictly in order: an event for version N only matches a copy at version N - 1.
# Otherwise it raises, stays unacked, and is redelivered after the missing update arrives.
class TicketCopyUpdate
  include ActiveModel::Model

  attr_accessor :id, :title, :price, :version

  def call
    ticket = Ticket.find_by!(id:, version: version - 1)
    ticket.update!(title:, price:, version:)
    ticket
  end
end
