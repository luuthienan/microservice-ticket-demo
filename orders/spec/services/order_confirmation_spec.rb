require "rails_helper"

RSpec.describe OrderConfirmation do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:order) { Order.create!(user_id: next_id, ticket:) }

  def with_expiration_window(value)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("EXPIRATION_WINDOW_SECONDS", anything) { |_, default| value || default }
  end

  it "moves a Pending order to awaiting payment with a deadline of 1 minute and publishes order:awaiting_payment" do
    with_expiration_window(nil) # the default; the environment may set its own
    described_class.new(order:).call

    expect(order.reload).to be_awaiting_payment
    expect(order.expires_at).to be_within(5.seconds).of(1.minute.from_now)
    expect(event_publisher).to have_received(:publish).with(
      "order:awaiting_payment",
      { id: order.id, version: 1, status: "awaiting_payment", user_id: order.user_id,
        expires_at: order.expires_at.iso8601, ticket: { id: ticket.id, price: ticket.price } }
    )
  end

  it "uses EXPIRATION_WINDOW_SECONDS for the deadline when set" do
    with_expiration_window("120")

    described_class.new(order:).call

    expect(order.reload.expires_at).to be_within(5.seconds).of(2.minutes.from_now)
  end

  ["abc", "0", "-5", ""].each do |value|
    it "raises ArgumentError without confirming the order when EXPIRATION_WINDOW_SECONDS is #{value.inspect}" do
      with_expiration_window(value)

      expect { described_class.new(order:).call }.to raise_error(ArgumentError, /EXPIRATION_WINDOW_SECONDS/)
      expect(order.reload).to be_created
      expect(ExpireOrderJob.jobs).to be_empty
    end
  end

  it "schedules the order to expire when its time is up" do
    described_class.new(order:).call

    expect(ExpireOrderJob.jobs.size).to eq(1)
    expect(ExpireOrderJob.jobs.first).to include("args" => [order.id], "at" => be_within(1).of(order.reload.expires_at.to_f))
  end

  it "leaves a cancelled order cancelled and publishes nothing" do
    order.cancelled!

    described_class.new(order:).call

    expect(order.reload).to be_cancelled
    expect(order.expires_at).to be_nil
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end

  it "does not publish again for an order already awaiting payment, as when ticket:reserved is replayed" do
    described_class.new(order:).call
    RSpec::Mocks.space.proxy_for(event_publisher).reset

    described_class.new(order: Order.find(order.id)).call

    expect(event_publisher).not_to have_received(:publish)
    expect(order.reload.lock_version).to eq(1)
  end

  it "leaves a paid order alone" do
    order.complete!

    described_class.new(order:).call

    expect(order.reload).to be_complete
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end
end
