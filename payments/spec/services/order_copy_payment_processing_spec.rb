require "rails_helper"

RSpec.describe OrderCopyPaymentProcessing do
  let!(:order) { Order.create!(id: next_id, user_id: next_id, price: 20, status: :awaiting_payment, version: 1) }

  it "moves the copy into payment processing at the next version" do
    described_class.new(id: order.id, version: 2).call

    expect(order.reload).to have_attributes(status: "payment_processing", version: 2)
  end

  it "ignores an update the copy already has, as when an event is replayed" do
    described_class.new(id: order.id, version: 2).call
    order.reload.update!(status: :awaiting_payment, version: 3)

    described_class.new(id: order.id, version: 2).call

    expect(order.reload).to have_attributes(status: "awaiting_payment", version: 3)
  end

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: order.id, version: 3).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
