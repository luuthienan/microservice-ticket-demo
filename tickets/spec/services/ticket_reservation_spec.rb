require "rails_helper"

RSpec.describe TicketReservation do
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: SecureRandom.uuid) }

  it "records the order on the ticket and publishes ticket:updated" do
    order_id = SecureRandom.uuid

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(ticket.reload.order_id).to eq(order_id)
    expect(Events).to have_received(:publish).with("ticket:updated", hash_including(order_id:, version: 1))
  end

  it "does not publish again when the order is already recorded" do
    order_id = SecureRandom.uuid
    ticket.update!(order_id:)

    described_class.new(ticket_id: ticket.id, order_id:).call

    expect(Events).not_to have_received(:publish)
  end
end
