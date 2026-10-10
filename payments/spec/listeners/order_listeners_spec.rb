require "rails_helper"

RSpec.describe "order listeners" do
  let(:order_id) { next_id }
  let(:created_event) do
    { "id" => order_id, "version" => 0, "status" => "created", "user_id" => next_id,
      "ticket" => { "id" => next_id, "price" => 20, "version" => 3 } }
  end
  let(:awaiting_payment_event) do
    { "id" => order_id, "version" => 1, "status" => "awaiting_payment", "user_id" => created_event["user_id"],
      "expires_at" => 1.minute.from_now.iso8601, "ticket" => { "id" => created_event["ticket"]["id"], "price" => 25 } }
  end

  describe OrderCreatedListener do
    it "stores a copy of the order, which cannot be paid yet" do
      described_class.new.handle(created_event)

      expect(Order.find(order_id)).to have_attributes(status: "created", price: 20, version: 0)
    end
  end

  describe OrderAwaitingPaymentListener do
    before { OrderCreatedListener.new.handle(created_event) }

    it "makes the order payable at the price of the reserved ticket" do
      described_class.new.handle(awaiting_payment_event)

      expect(Order.find(order_id)).to have_attributes(status: "awaiting_payment", price: 25, version: 1)
    end
  end

  describe OrderCancelledListener do
    before { OrderCreatedListener.new.handle(created_event) }

    it "marks a Pending order cancelled" do
      described_class.new.handle("id" => order_id, "version" => 1)

      expect(Order.find(order_id)).to have_attributes(status: "cancelled", version: 1)
    end

    it "marks an order that was awaiting payment cancelled" do
      OrderAwaitingPaymentListener.new.handle(awaiting_payment_event)

      described_class.new.handle("id" => order_id, "version" => 2)

      expect(Order.find(order_id)).to have_attributes(status: "cancelled", version: 2)
    end

    it "refuses an event that skips a version" do
      expect { described_class.new.handle("id" => order_id, "version" => 2) }
        .to raise_error(ActiveRecord::RecordNotFound)
      expect(Order.find(order_id)).to be_created
    end
  end
end
