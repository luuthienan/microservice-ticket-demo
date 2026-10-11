require "rails_helper"

RSpec.describe OrderCopyCancellation do
  let!(:order) { Order.create!(id: next_id, user_id: next_id, price: 20, status: :created, version: 0) }

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

  it "raises when a version was skipped so the event is redelivered" do
    expect { described_class.new(id: order.id, version: 2).call }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "fails a payment still waiting for the order to be claimed, since there is nothing left to charge" do
    pending_payment = Payment.create!(order:, token: "tok_visa")
    paid_payment = Payment.create!(order: Order.create!(id: next_id, user_id: next_id, price: 20, status: :created), status: :paid)

    described_class.new(id: order.id, version: 1).call

    expect(pending_payment.reload).to have_attributes(status: "failed", failure_message: "Order was cancelled")
    expect(paid_payment.reload).to be_paid
    expect(event_publisher).not_to have_received(:publish)
  end
end

