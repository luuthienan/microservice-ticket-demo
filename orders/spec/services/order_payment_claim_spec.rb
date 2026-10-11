require "rails_helper"

RSpec.describe OrderPaymentClaim do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:payment_id) { next_id }
  let(:order) { Order.create!(user_id: next_id, ticket:, status: :awaiting_payment, expires_at: 15.minutes.from_now) }

  it "moves an order awaiting payment to payment processing and publishes order:payment_processing" do
    described_class.new(order:, payment_id:).call

    expect(order.reload).to have_attributes(status: "payment_processing", payment_id:)
    expect(event_publisher).to have_received(:publish).with(
      "order:payment_processing",
      { id: order.id, version: 1, status: "payment_processing", user_id: order.user_id, payment_id:, ticket: { id: ticket.id } }
    )
  end

  it "does nothing the second time, as when the event is replayed" do
    described_class.new(order:, payment_id:).call
    RSpec::Mocks.space.proxy_for(event_publisher).reset

    described_class.new(order: Order.find(order.id), payment_id:).call

    expect(order.reload.lock_version).to eq(1)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "claims the order again for a later payment once the first one failed" do
    order.update!(payment_id:)

    described_class.new(order:, payment_id: payment_id + 1).call

    expect(order.reload).to have_attributes(status: "payment_processing", payment_id: payment_id + 1)
  end

  it "ignores an earlier payment than the one the order was last claimed for, as when a stale request is replayed" do
    order.update!(payment_id:)

    described_class.new(order:, payment_id: payment_id - 1).call

    expect(order.reload).to be_awaiting_payment
    expect(event_publisher).not_to have_received(:publish)
  end

  %i[created cancelled complete].each do |status|
    it "leaves an order that is #{status} alone" do
      order.update!(status:)

      described_class.new(order:, payment_id:).call

      expect(order.reload.status).to eq(status.to_s)
      expect(order.payment_id).to be_nil
      expect(event_publisher).not_to have_received(:publish)
    end
  end

  it "loses to an expiry that cancelled the order since it was loaded, so the order is never claimed and cancelled" do
    stale = Order.find(order.id)
    OrderCancellation.new(order:).call

    expect { described_class.new(order: stale, payment_id:).call }.to raise_error(ActiveRecord::StaleObjectError)
    expect(order.reload).to be_cancelled
    expect(order.payment_id).to be_nil
  end
end
