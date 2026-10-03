# Stores a local copy of a ticket owned by the tickets service.
class TicketCopyCreation
  include ActiveModel::Model

  attr_accessor :id, :title, :price, :version

  def call
    Ticket.create!(id:, title:, price:, version:)
  end
end
