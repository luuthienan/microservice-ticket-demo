# Applies updates strictly in order: an event for version N only applies to a copy at version N - 1.
# An update the copy already has (a replay or a duplicate) is ignored. A gap raises, so the event is
# retried until the missing update arrives, then dead-lettered.
class TicketCopyUpdate
  include ActiveModel::Model

  attr_accessor :id, :title, :price, :status, :version

  def call
    ticket = Ticket.find(id)
    return ticket if version <= ticket.version

    ticket = Ticket.find_by!(id:, version: version - 1)
    ticket.update!(title:, price:, status:, version:)
    ticket
  end
end
