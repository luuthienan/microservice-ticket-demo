require "rails_helper"

RSpec.describe TicketRelease do
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id, order_id: next_id) }

  it "clears the order and publishes ticket:updated" do
    described_class.new(ticket_id: ticket.id).call

    expect(ticket.reload.order_id).to be_nil
    expect(Events).to have_received(:publish).with("ticket:updated", hash_including(order_id: nil))
  end
end
