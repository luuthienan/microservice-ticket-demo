require "rails_helper"

RSpec.describe Ticket do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }

  it "is available until the tickets service says otherwise" do
    expect(ticket).to be_available
    expect(ticket).not_to be_reserved
  end

  it "follows the status the tickets service sent" do
    ticket.status = "reserved"

    expect(ticket).to be_reserved
    expect(ticket).not_to be_available
  end

  it "is not reserved just because it has an order, until the tickets service says so" do
    Order.create!(user_id: next_id, ticket:, expires_at: 15.minutes.from_now)

    expect(ticket).not_to be_reserved
  end
end
