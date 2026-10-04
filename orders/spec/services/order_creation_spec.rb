require "rails_helper"

RSpec.describe OrderCreation do
  let(:user_id) { next_id }
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }

  def call(ticket_id: ticket.id) = described_class.new(ticket_id:, user_id:)

  it "creates an order expiring in 15 minutes and publishes order:created" do
    order = call.call

    expect(order).to have_attributes(user_id:, status: "created", ticket:)
    expect(order.expires_at).to be_within(1.minute).of(15.minutes.from_now)
    expect(event_publisher).to have_received(:publish).with(
      "order:created",
      { id: order.id, version: 0, status: "created", user_id:, expires_at: order.expires_at.iso8601,
        ticket: { id: ticket.id, price: ticket.price } }
    )
  end

  it "fails with an error when the ticket is already reserved" do
    Order.create!(user_id: next_id, ticket:, expires_at: 15.minutes.from_now)
    service = call

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Ticket is already reserved"])
    expect(Order.count).to eq(1)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { call(ticket_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
