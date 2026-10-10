require "rails_helper"

RSpec.describe TicketCopyUpdate do
  let!(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20, version: 0) }

  it "applies the next version" do
    described_class.new(id: ticket.id, title: "game", price: 30, status: "reserved", version: 1).call

    expect(ticket.reload).to have_attributes(title: "game", price: 30, status: "reserved", version: 1)
  end

  it "follows a seller cancelling the ticket" do
    described_class.new(id: ticket.id, title: "concert", price: 20, status: "cancelled", version: 1).call

    expect(ticket.reload).to have_attributes(status: "cancelled", version: 1)
  end

  it "ignores an update the copy already has, as when an event is replayed" do
    described_class.new(id: ticket.id, title: "game", price: 30, status: "reserved", version: 1).call
    described_class.new(id: ticket.id, title: "old", price: 1, status: "available", version: 1).call
    described_class.new(id: ticket.id, title: "older", price: 1, status: "available", version: 0).call

    expect(ticket.reload).to have_attributes(title: "game", price: 30, status: "reserved", version: 1)
  end

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: ticket.id, title: "game", price: 30, status: "available", version: 2).call }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
