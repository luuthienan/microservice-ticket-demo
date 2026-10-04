require "rails_helper"

RSpec.describe TicketCopyCreation do
  it "stores a copy of the ticket at the given version" do
    id = next_id

    described_class.new(id:, title: "concert", price: 20, version: 0).call

    expect(Ticket.find(id)).to have_attributes(title: "concert", price: 20, version: 0)
  end

  it "keeps the copy as it is when the event is delivered again" do
    id = next_id
    described_class.new(id:, title: "concert", price: 20, version: 0).call
    Ticket.find(id).update!(title: "game", version: 1)

    expect { described_class.new(id:, title: "concert", price: 20, version: 0).call }.not_to raise_error

    expect(Ticket.find(id)).to have_attributes(title: "game", version: 1)
  end
end
