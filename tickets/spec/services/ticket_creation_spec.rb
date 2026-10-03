require "rails_helper"

RSpec.describe TicketCreation do
  it "creates the ticket and publishes ticket:created" do
    user_id = next_id

    ticket = described_class.new(title: "concert", price: 10, user_id:).call

    expect(ticket).to have_attributes(title: "concert", price: 10, user_id:)
    expect(Events).to have_received(:publish).with(
      "ticket:created",
      { id: ticket.id, title: "concert", price: 10, user_id:, order_id: nil, version: 0 }
    )
  end
end
