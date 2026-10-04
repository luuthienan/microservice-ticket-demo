require "rails_helper"

RSpec.describe OrderCreation do
  let(:user_id) { next_id }
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }

  def call(ticket_id: ticket.id) = described_class.new(ticket_id:, user_id:)

  def with_expiration_window(value)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("EXPIRATION_WINDOW_SECONDS", anything).and_return(value)
  end

  it "creates an order expiring in 1 minute and publishes order:created" do
    order = call.call

    expect(order).to have_attributes(user_id:, status: "created", ticket:)
    expect(order.expires_at).to be_within(5.seconds).of(1.minute.from_now)
    expect(event_publisher).to have_received(:publish).with(
      "order:created",
      { id: order.id, version: 0, status: "created", user_id:, expires_at: order.expires_at.iso8601,
        ticket: { id: ticket.id, price: ticket.price } }
    )
  end

  it "uses EXPIRATION_WINDOW_SECONDS for the expiry when set" do
    with_expiration_window("120")

    expect(call.call.expires_at).to be_within(5.seconds).of(2.minutes.from_now)
  end

  ["abc", "0", "-5", ""].each do |value|
    it "raises ArgumentError without creating an order when EXPIRATION_WINDOW_SECONDS is #{value.inspect}" do
      with_expiration_window(value)

      expect { call.call }.to raise_error(ArgumentError, /EXPIRATION_WINDOW_SECONDS/)
      expect(Order.count).to eq(0)
      expect(ExpireOrderJob.jobs).to be_empty
    end
  end

  it "schedules the order to expire when its time is up" do
    order = call.call

    expect(ExpireOrderJob.jobs.size).to eq(1)
    expect(ExpireOrderJob.jobs.first).to include("args" => [order.id], "at" => be_within(1).of(order.expires_at.to_f))
  end

  it "fails with an error when the ticket is already reserved" do
    Order.create!(user_id: next_id, ticket:, expires_at: 15.minutes.from_now)
    service = call

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Ticket is already reserved"])
    expect(Order.count).to eq(1)
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { call(ticket_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
