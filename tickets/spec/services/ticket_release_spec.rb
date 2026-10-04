require "rails_helper"

RSpec.describe TicketRelease do
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id, order_id: next_id) }

  it "clears the order and publishes ticket:updated" do
    described_class.new(ticket_id: ticket.id, order_id: ticket.order_id).call

    expect(ticket.reload.order_id).to be_nil
    expect(event_publisher).to have_received(:publish).with("ticket:updated", hash_including(order_id: nil))
  end

  it "keeps a ticket that a newer order now holds, as when an old cancellation is replayed" do
    held_by = ticket.order_id

    described_class.new(ticket_id: ticket.id, order_id: next_id).call

    expect(ticket.reload.order_id).to eq(held_by)
    expect(event_publisher).not_to have_received(:publish)
  end
end
