require "rails_helper"

RSpec.describe "order listeners" do
  let(:order_id) { SecureRandom.uuid }
  let(:created_event) do
    { "id" => order_id, "version" => 0, "status" => "created", "user_id" => SecureRandom.uuid,
      "ticket" => { "id" => SecureRandom.uuid, "price" => 20 } }
  end

  describe OrderCreatedListener do
    it "stores a copy of the order" do
      described_class.new.handle(created_event)

      expect(Order.find(order_id)).to have_attributes(status: "created", price: 20, version: 0)
    end
  end

  describe OrderCancelledListener do
    before { OrderCreatedListener.new.handle(created_event) }

    it "marks the order cancelled" do
      described_class.new.handle("id" => order_id, "version" => 1)

      expect(Order.find(order_id)).to have_attributes(status: "cancelled", version: 1)
    end

    it "refuses an event that skips a version" do
      expect { described_class.new.handle("id" => order_id, "version" => 2) }
        .to raise_error(ActiveRecord::RecordNotFound)
      expect(Order.find(order_id)).to be_created
    end
  end
end
