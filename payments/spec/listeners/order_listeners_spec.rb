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

  describe OrderPaymentProcessingListener do
    let(:user_id) { created_event["user_id"] }
    let(:processing_event) { { "id" => order_id, "version" => 2, "status" => "payment_processing", "payment_id" => payment.id } }
    let(:payment) { Payment.create!(order: Order.find(order_id), token: "tok_visa") }

    before do
      allow(Stripe::Charge).to receive(:create).and_return(double(id: "ch_123"))
      OrderCreatedListener.new.handle(created_event)
      OrderAwaitingPaymentListener.new.handle(awaiting_payment_event)
    end

    it "follows the order into payment processing and charges the payment the event names" do
      described_class.new.handle(processing_event)

      expect(Order.find(order_id)).to have_attributes(status: "payment_processing", version: 2)
      expect(payment.reload).to have_attributes(status: "paid", stripe_id: "ch_123")
    end

    it "charges nothing the second time, as when the event is replayed" do
      described_class.new.handle(processing_event)
      described_class.new.handle(processing_event)

      expect(Stripe::Charge).to have_received(:create).once
    end

    it "retries the charge after the copy was already updated, as when Stripe was unreachable" do
      allow(Stripe::Charge).to receive(:create).and_raise(Stripe::APIConnectionError.new("down"))
      expect { described_class.new.handle(processing_event) }.to raise_error(Stripe::APIConnectionError)
      allow(Stripe::Charge).to receive(:create).and_return(double(id: "ch_123"))

      described_class.new.handle(processing_event)

      expect(payment.reload).to be_paid
    end

    it "makes the order payable again with the awaiting payment event that follows a declined payment" do
      described_class.new.handle(processing_event)

      OrderAwaitingPaymentListener.new.handle(awaiting_payment_event.merge("version" => 3))

      expect(Order.find(order_id)).to have_attributes(status: "awaiting_payment", version: 3)
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
