require "rails_helper"

RSpec.describe OrderCompletion do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:order) { Order.create!(user_id: next_id, ticket:, status: :awaiting_payment, expires_at: 15.minutes.from_now) }

  it "marks the order complete and publishes order:completed" do
    described_class.new(order:).call

    expect(order.reload).to be_complete
    expect(event_publisher).to have_received(:publish).with(
      "order:completed",
      { id: order.id, version: 1, status: "complete", user_id: order.user_id, ticket: { id: ticket.id } }
    )
  end

  it "does not publish again for an order that is already complete, as when a payment is replayed" do
    order.complete!

    described_class.new(order:).call

    expect(event_publisher).not_to have_received(:publish)
  end

  it "fails with an error when the order is still Pending, so was never confirmed" do
    order.created!
    service = described_class.new(order:)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order is not awaiting payment"])
    expect(order.reload).to be_created
    expect(event_publisher).not_to have_received(:publish)
  end

  it "fails with an error when the order was cancelled" do
    order.cancelled!
    service = described_class.new(order:)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order is cancelled"])
    expect(order.reload).to be_cancelled
    expect(event_publisher).not_to have_received(:publish)
  end
end
