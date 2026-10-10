require "rails_helper"

RSpec.describe TicketSale do
  let(:order_id) { next_id }
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id, status: :reserved, order_id:) }

  it "marks the ticket sold, keeps the order and publishes ticket:updated" do
    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(ticket.reload).to have_attributes(status: "sold", order_id:)
    expect(event_publisher).to have_received(:publish)
      .with("ticket:updated", hash_including(order_id:, status: "sold", version: 1))
  end

  it "does not publish again when the ticket is already sold to the order" do
    ticket.update!(status: :sold)

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(ticket.reload.status).to eq("sold")
    expect(event_publisher).not_to have_received(:publish)
  end

  it "ignores an order that does not hold the ticket" do
    described_class.new(ticket_id: ticket.id, order_id: next_id).call

    expect(ticket.reload).to have_attributes(status: "reserved", order_id:)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "ignores an order for a ticket that was released" do
    ticket.update!(status: :available, order_id: nil)

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(ticket.reload.status).to eq("available")
    expect(event_publisher).not_to have_received(:publish)
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { described_class.new(ticket_id: next_id, order_id:).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
