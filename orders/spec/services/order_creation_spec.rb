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

  it "fails the same way when another order wins the race after the reserved check" do
    Order.create!(user_id: next_id, ticket:, expires_at: 15.minutes.from_now)
    allow_any_instance_of(Ticket).to receive(:reserved?).and_return(false)
    service = call

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Ticket is already reserved"])
    expect(Order.count).to eq(1)
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end

  %w[reserved sold cancelled].each do |status|
    it "fails with an error when the ticket is #{status} according to the tickets service" do
      ticket.update!(status:)
      service = call

      expect(service.call).to be(false)
      expect(service.errors.full_messages).to eq(["Ticket is not available"])
      expect(Order.count).to eq(0)
      expect(event_publisher).not_to have_received(:publish)
      expect(ExpireOrderJob.jobs).to be_empty
    end
  end

  it "lets a ticket be ordered again once its order is cancelled" do
    Order.create!(user_id: next_id, ticket:, status: :cancelled, expires_at: 15.minutes.from_now)

    expect(call.call).to be_a(Order)
    expect(Order.where(ticket:).count).to eq(2)
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { call(ticket_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "when two users order the same ticket at the same time" do
    self.use_transactional_tests = false

    after do
      Order.where(ticket_id: ticket.id).delete_all
      ticket.destroy
    end

    it "creates exactly one order" do
      allow_any_instance_of(Ticket).to receive(:reserved?).and_return(false) # both pass the check, as in a real race
      ticket && user_id # memoize `let`s before the threads read them
      start = Queue.new
      results = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            start.pop
            call.call
          end
        end
      end.tap { 2.times { start << :go } }.map(&:value)

      expect(results.count(false)).to eq(1)
      expect(results.grep(Order).size).to eq(1)
      expect(Order.where(ticket_id: ticket.id).count).to eq(1)
    end
  end
end
