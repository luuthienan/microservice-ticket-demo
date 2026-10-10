require "rails_helper"

RSpec.describe OrderCancellation do
  let(:user_id) { next_id }
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:order) { Order.create!(user_id:, ticket:, expires_at: 15.minutes.from_now) }

  it "cancels the order and publishes order:cancelled with the new version" do
    described_class.new(order:, user_id:).call

    expect(order.reload).to be_cancelled
    expect(event_publisher).to have_received(:publish)
      .with("order:cancelled", { id: order.id, version: 1, ticket: { id: ticket.id } })
  end

  it "cancels an order awaiting payment" do
    order.awaiting_payment!

    described_class.new(order:, user_id:).call

    expect(order.reload).to be_cancelled
    expect(event_publisher).to have_received(:publish).with("order:cancelled", hash_including(id: order.id))
  end

  it "cancels without an owner check when no user is given (system-initiated)" do
    described_class.new(order:).call

    expect(order.reload).to be_cancelled
  end

  it "fails with an error when the order is already paid" do
    order.complete!
    service = described_class.new(order:, user_id:)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order cannot be cancelled"])
    expect(order.reload).to be_complete
    expect(event_publisher).not_to have_received(:publish)
  end

  it "rejects another user's order" do
    expect { described_class.new(order:, user_id: next_id).call }.to raise_error(ApiError::NotAuthorized)

    expect(order.reload).to be_created
    expect(event_publisher).not_to have_received(:publish)
  end
end
