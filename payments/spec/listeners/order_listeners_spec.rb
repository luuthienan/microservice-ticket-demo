require "rails_helper"

RSpec.describe "order listeners" do
  let(:order_id) { next_id }
  let(:awaiting_payment_event) do
    { "id" => order_id, "version" => 1, "status" => "awaiting_payment", "user_id" => next_id,
      "expires_at" => 1.minute.from_now.iso8601, "ticket" => { "id" => next_id, "price" => 20 } }
  end

  describe OrderAwaitingPaymentListener do
    it "stores a copy of the order" do
      described_class.new.handle(awaiting_payment_event)

      expect(Order.find(order_id)).to have_attributes(status: "awaiting_payment", price: 20, version: 1)
    end
  end

  describe OrderCancelledListener do
    before { OrderAwaitingPaymentListener.new.handle(awaiting_payment_event) }

    it "marks the order cancelled" do
      described_class.new.handle("id" => order_id, "version" => 2)

      expect(Order.find(order_id)).to have_attributes(status: "cancelled", version: 2)
    end

    it "refuses an event that skips a version" do
      expect { described_class.new.handle("id" => order_id, "version" => 3) }
        .to raise_error(ActiveRecord::RecordNotFound)
      expect(Order.find(order_id)).to be_awaiting_payment
    end

    it "ignores an order that was cancelled while Pending, so was never copied" do
      expect { described_class.new.handle("id" => next_id, "version" => 1) }.not_to raise_error
    end
  end
end
