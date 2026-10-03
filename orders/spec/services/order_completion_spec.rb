require "rails_helper"

RSpec.describe OrderCompletion do
  it "marks the order complete" do
    ticket = Ticket.create!(title: "concert", price: 20)
    order = Order.create!(user_id: SecureRandom.uuid, ticket:, expires_at: 15.minutes.from_now)

    described_class.new(order:).call

    expect(order.reload).to be_complete
  end
end
