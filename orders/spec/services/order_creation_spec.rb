require "rails_helper"

RSpec.describe OrderCreation do
  let(:user_id) { next_id }
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }

  def call(ticket_id: ticket.id) = described_class.new(ticket_id:, user_id:)

  it "creates a Pending order with no deadline and publishes order:created with the ticket's version" do
    ticket.update!(version: 3, price: 25)
    order = call.call

    expect(order).to have_attributes(user_id:, status: "created", expires_at: nil, ticket:)
    expect(event_publisher).to have_received(:publish).with(
      "order:created",
      { id: order.id, version: 0, status: "created", user_id:,
        ticket: { id: ticket.id, price: ticket.price, version: 3 } }
    )
  end

  it "does not schedule the order to expire, since it only has a deadline once confirmed" do
    call.call

    expect(ExpireOrderJob.jobs).to be_empty
  end

  it "fails with an error when an order holds the ticket but the Copy has not caught up yet" do
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

  it "fails with an error when the ticket is reserved according to the tickets service" do
    ticket.update!(status: :reserved)
    service = call

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Ticket is already reserved"])
    expect(Order.count).to eq(0)
    expect(event_publisher).not_to have_received(:publish)
    expect(ExpireOrderJob.jobs).to be_empty
  end

  %w[sold cancelled].each do |status|
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
