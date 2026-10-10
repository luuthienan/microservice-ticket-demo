require "rails_helper"

RSpec.describe OrderCopyCancellation do
  let!(:order) { Order.create!(id: next_id, user_id: next_id, price: 20, status: :awaiting_payment, version: 0) }

  it "cancels the copy at the next version" do
    described_class.new(id: order.id, version: 1).call

    expect(order.reload).to have_attributes(status: "cancelled", version: 1)
  end

  it "ignores a cancellation the copy already has, as when an event is replayed" do
    described_class.new(id: order.id, version: 1).call
    described_class.new(id: order.id, version: 1).call
    described_class.new(id: order.id, version: 0).call

    expect(order.reload).to have_attributes(status: "cancelled", version: 1)
  end

  it "does nothing for an order with no copy, as when a Pending order is cancelled" do
    expect(described_class.new(id: next_id, version: 1).call).to be_nil
  end

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: order.id, version: 2).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
