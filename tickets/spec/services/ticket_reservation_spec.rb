require "rails_helper"

RSpec.describe TicketReservation do
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id) }

  it "records the order on the ticket and publishes ticket:updated" do
    order_id = next_id

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(ticket.reload.order_id).to eq(order_id)
    expect(event_publisher).to have_received(:publish).with("ticket:updated", hash_including(order_id:, version: 1))
  end

  it "leaves a ticket held by another order with that order, as when an old order:created is replayed" do
    held_by = next_id
    ticket.update!(order_id: held_by)

    described_class.new(ticket_id: ticket.id, order_id: next_id).call

    expect(ticket.reload.order_id).to eq(held_by)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "does not publish again when the order is already recorded" do
    order_id = next_id
    ticket.update!(order_id:)

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(event_publisher).not_to have_received(:publish)
  end
end
