require "rails_helper"

RSpec.describe OrderPaymentRelease do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:payment_id) { next_id }
  let(:order) do
    Order.create!(user_id: next_id, ticket:, status: :payment_processing, payment_id:, expires_at: 15.minutes.from_now)
  end

  it "puts the order back to awaiting payment, keeping its deadline, and publishes order:awaiting_payment" do
    deadline = order.expires_at

    described_class.new(order:, payment_id:).call

    expect(order.reload).to have_attributes(status: "awaiting_payment", expires_at: deadline)
    expect(event_publisher).to have_received(:publish).with(
      "order:awaiting_payment",
      { id: order.id, version: 1, status: "awaiting_payment", user_id: order.user_id,
        expires_at: order.expires_at.iso8601, ticket: { id: ticket.id, price: ticket.price } }
    )
  end

  it "schedules the order to expire at its deadline again, since expiry skipped it while it was claimed" do
    described_class.new(order:, payment_id:).call

    expect(ExpireOrderJob.jobs.size).to eq(1)
    expect(ExpireOrderJob.jobs.first).to include("args" => [order.id], "at" => be_within(1).of(order.reload.expires_at.to_f))
  end

  it "runs expiry at once when the deadline passed while the card was being charged" do
    order.update!(expires_at: 1.minute.ago)

    described_class.new(order:, payment_id:).call

    expect(ExpireOrderJob.jobs.size).to eq(1)
    expect(ExpireOrderJob.jobs.first["at"]).to be_nil.or be < Time.now.to_f
  end

  it "ignores a payment the order is not claimed for, as when an earlier failure is replayed" do
    described_class.new(order:, payment_id: payment_id - 1).call

    expect(order.reload).to be_payment_processing
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end

  it "publishes nothing the second time but schedules expiry again, as when the event is replayed" do
    described_class.new(order:, payment_id:).call
    RSpec::Mocks.space.proxy_for(event_publisher).reset
    ExpireOrderJob.jobs.clear

    described_class.new(order: Order.find(order.id), payment_id:).call

    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs.size).to eq(1)
  end

  %i[cancelled complete].each do |status|
    it "leaves an order that is #{status} alone" do
      order.update!(status:)

      described_class.new(order:, payment_id:).call

      expect(order.reload.status).to eq(status.to_s)
      expect(event_publisher).not_to have_received(:publish)
      expect(ExpireOrderJob.jobs).to be_empty
    end
  end
end
