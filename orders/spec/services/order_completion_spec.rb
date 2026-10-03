require "rails_helper"

RSpec.describe OrderCompletion do
  let(:ticket) { Ticket.create!(title: "concert", price: 20) }
  let(:order) { Order.create!(user_id: SecureRandom.uuid, ticket:, expires_at: 15.minutes.from_now) }

  it "marks the order complete" do
    described_class.new(order:).call

    expect(order.reload).to be_complete
  end

  it "fails with an error when the order was cancelled" do
    order.cancelled!
    service = described_class.new(order:)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order is cancelled"])
    expect(order.reload).to be_cancelled
  end
end
