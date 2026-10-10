require "rails_helper"

RSpec.describe "order listeners" do
  let(:order_id) { next_id }
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id) }
  let(:data) { { "id" => order_id, "ticket" => { "id" => ticket.id } } }

  describe OrderCreatedListener do
    it "reserves the ticket and publishes ticket:updated" do
      described_class.new.handle(data)

      expect(ticket.reload).to have_attributes(status: "reserved", order_id:)
      expect(event_publisher).to have_received(:publish)
        .with("ticket:updated", hash_including(order_id:, status: "reserved", version: ticket.lock_version))
    end
  end

  describe OrderCancelledListener do
    it "makes the ticket available again and publishes ticket:updated" do
      ticket.update!(status: :reserved, order_id:)

      described_class.new.handle(data)

      expect(ticket.reload).to have_attributes(status: "available", order_id: nil)
      expect(event_publisher).to have_received(:publish)
        .with("ticket:updated", hash_including(order_id: nil, status: "available"))
    end
  end

  describe OrderCompletedListener do
    it "marks the ticket sold and publishes ticket:updated" do
      ticket.update!(status: :reserved, order_id:)

      described_class.new.handle(data)

      expect(ticket.reload).to have_attributes(status: "sold", order_id:)
      expect(event_publisher).to have_received(:publish)
        .with("ticket:updated", hash_including(order_id:, status: "sold"))
    end
  end
end
