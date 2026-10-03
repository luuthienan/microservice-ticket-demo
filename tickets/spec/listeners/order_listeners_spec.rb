require "rails_helper"

RSpec.describe "order listeners" do
  let(:order_id) { next_id }
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id) }
  let(:data) { { "id" => order_id, "ticket" => { "id" => ticket.id } } }

  describe OrderCreatedListener do
    it "locks the ticket and publishes ticket:updated" do
      described_class.new.handle(data)

      expect(ticket.reload.order_id).to eq(order_id)
      expect(Events).to have_received(:publish)
        .with("ticket:updated", hash_including(order_id:, version: ticket.lock_version))
    end
  end

  describe OrderCancelledListener do
    it "unlocks the ticket and publishes ticket:updated" do
      ticket.update!(order_id:)

      described_class.new.handle(data)

      expect(ticket.reload.order_id).to be_nil
      expect(Events).to have_received(:publish).with("ticket:updated", hash_including(order_id: nil))
    end
  end
end
