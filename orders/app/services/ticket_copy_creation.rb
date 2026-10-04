# Stores a local copy of a ticket owned by the tickets service. A copy that already exists is kept as is.
class TicketCopyCreation
  include ActiveModel::Model

  attr_accessor :id, :title, :price, :version

  def call
    Ticket.find_or_create_by!(id:) { |ticket| ticket.assign_attributes(title:, price:, version:) }
  end
end
