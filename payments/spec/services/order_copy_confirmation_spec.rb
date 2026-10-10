require "rails_helper"

RSpec.describe OrderCopyConfirmation do
  let!(:order) { Order.create!(id: next_id, user_id: next_id, price: 20, status: :created, version: 0) }

  it "moves the copy to awaiting payment at the next version, with the price of the reserved ticket" do
    described_class.new(id: order.id, price: 25, version: 1).call

    expect(order.reload).to have_attributes(status: "awaiting_payment", price: 25, version: 1)
  end

  it "ignores a confirmation the copy already has, as when an event is replayed" do
    described_class.new(id: order.id, price: 25, version: 1).call
    described_class.new(id: order.id, price: 30, version: 1).call

    expect(order.reload).to have_attributes(status: "awaiting_payment", price: 25, version: 1)
  end

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: order.id, price: 25, version: 2).call }.to raise_error(ActiveRecord::RecordNotFound)
    expect(order.reload).to be_created
  end
end
