require "rails_helper"

RSpec.describe TicketCopyUpdate do
  let!(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20, version: 0) }

  it "applies the next version" do
    described_class.new(id: ticket.id, title: "game", price: 30, version: 1).call

    expect(ticket.reload).to have_attributes(title: "game", price: 30, version: 1)
  end

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: ticket.id, title: "game", price: 30, version: 2).call }
      .to raise_error(ActiveRecord::RecordNotFound)
  end
end
