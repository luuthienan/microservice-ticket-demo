require "rails_helper"

RSpec.describe OrderCompletion do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:payment_id) { next_id }
  let(:order) { Order.create!(user_id: next_id, ticket:, status: :payment_processing, payment_id:, expires_at: 15.minutes.from_now) }

  it "marks the order claimed for the payment complete and publishes order:completed" do
    described_class.new(order:, payment_id:).call

    expect(order.reload).to be_complete
    expect(event_publisher).to have_received(:publish).with(
      "order:completed",
      { id: order.id, version: 1, status: "complete", user_id: order.user_id, ticket: { id: ticket.id } }
    )
  end

  it "does not publish again for an order that is already complete, as when a payment is replayed" do
    order.complete!

    described_class.new(order:, payment_id:).call

    expect(event_publisher).not_to have_received(:publish)
  end

  it "fails with an error for a payment the order was not claimed for, as when an earlier attempt is replayed" do
    service = described_class.new(order:, payment_id: payment_id - 1)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order is not processing this payment"])
    expect(order.reload).to be_payment_processing
    expect(event_publisher).not_to have_received(:publish)
  end

  %i[created awaiting_payment].each do |status|
    it "fails with an error when the order is #{status}, so no payment claimed it" do
      order.update!(status:)
      service = described_class.new(order:, payment_id:)

      expect(service.call).to be(false)
      expect(service.errors.full_messages).to eq(["Order is not processing this payment"])
      expect(order.reload.status).to eq(status.to_s)
      expect(event_publisher).not_to have_received(:publish)
    end
  end

  it "fails with an error when the order was cancelled" do
    order.cancelled!
    service = described_class.new(order:, payment_id:)

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Order is cancelled"])
    expect(order.reload).to be_cancelled
    expect(event_publisher).not_to have_received(:publish)
  end
end
