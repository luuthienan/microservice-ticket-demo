require "rails_helper"

RSpec.describe ExpireOrderJob do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }

  def create_order(status: :awaiting_payment)
    Order.create!(user_id: next_id, ticket:, status:, expires_at: 15.minutes.from_now)
  end

  it "cancels an order awaiting payment and publishes order:cancelled" do
    order = create_order

    described_class.new.perform(order.id)

    expect(order.reload).to be_cancelled
    expect(event_publisher).to have_received(:publish).with("order:cancelled", hash_including(id: order.id))
  end

  it "leaves a Pending order alone, since it has no deadline" do
    order = create_order(status: :created)

    described_class.new.perform(order.id)

    expect(order.reload).to be_created
    expect(event_publisher).not_to have_received(:publish)
  end

  it "leaves a complete order alone" do
    order = create_order(status: :complete)

    described_class.new.perform(order.id)

    expect(order.reload).to be_complete
    expect(event_publisher).not_to have_received(:publish)
  end

  it "leaves an order that is already cancelled alone" do
    order = create_order(status: :cancelled)

    described_class.new.perform(order.id)

    expect(order.reload).to be_cancelled
    expect(event_publisher).not_to have_received(:publish)
  end
end
