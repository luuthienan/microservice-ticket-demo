require "rails_helper"

RSpec.describe Ticket do
  let(:ticket) { Ticket.create!(id: next_id, title: "concert", price: 20) }
  let(:order_attrs) { { user_id: next_id, ticket:, expires_at: 15.minutes.from_now } }

  describe "#reserved?" do
    it "is false without orders" do
      expect(ticket).not_to be_reserved
    end

    it "is true with an active order" do
      Order.create!(order_attrs)

      expect(ticket).to be_reserved
    end

    it "is false when the order is cancelled" do
      Order.create!(order_attrs.merge(status: :cancelled))

      expect(ticket).not_to be_reserved
    end
  end
end
