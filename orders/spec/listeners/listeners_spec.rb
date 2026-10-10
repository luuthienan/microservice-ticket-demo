require "rails_helper"

RSpec.describe "listeners" do
  let(:ticket_id) { next_id }

  def ticket_event(version:, title: "concert", price: 20, status: "available")
    { "id" => ticket_id, "title" => title, "price" => price, "status" => status, "version" => version }
  end

  def create_order(status: :created)
    Order.create!(user_id: next_id, ticket: Ticket.find(ticket_id), status:, expires_at: 15.minutes.from_now)
  end

  describe TicketCreatedListener do
    it "stores a copy of the ticket" do
      described_class.new.handle(ticket_event(version: 0))

      expect(Ticket.find(ticket_id)).to have_attributes(title: "concert", price: 20, status: "available", version: 0)
    end
  end

  describe TicketUpdatedListener do
    before { TicketCreatedListener.new.handle(ticket_event(version: 0)) }

    it "applies the next version" do
      described_class.new.handle(ticket_event(version: 1, title: "new", price: 99, status: "sold"))

      expect(Ticket.find(ticket_id)).to have_attributes(title: "new", price: 99, status: "sold", version: 1)
    end

    it "ignores an event it has already applied" do
      described_class.new.handle(ticket_event(version: 1, title: "new", price: 99))
      described_class.new.handle(ticket_event(version: 1, title: "new", price: 99))

      expect(Ticket.find(ticket_id)).to have_attributes(title: "new", version: 1)
    end

    it "refuses an event that skips a version" do
      expect { described_class.new.handle(ticket_event(version: 2)) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(Ticket.find(ticket_id).version).to eq(0)
    end
  end

  describe TicketReservedListener do
    before { TicketCreatedListener.new.handle(ticket_event(version: 0)) }

    def reserved_event(order, version: 1, price: 20)
      ticket_event(version:, price:, status: "reserved").merge("order_id" => order.id)
    end

    it "applies the reservation to the Copy and moves the Pending order to awaiting payment" do
      order = create_order

      described_class.new.handle(reserved_event(order, price: 25))

      expect(Ticket.find(ticket_id)).to have_attributes(status: "reserved", price: 25, version: 1)
      expect(order.reload).to be_awaiting_payment
      expect(order.expires_at).to be > Time.current
      expect(event_publisher).to have_received(:publish).with(
        "order:awaiting_payment", hash_including(id: order.id, ticket: { id: ticket_id, price: 25 })
      )
    end

    it "keeps the Copy in step but leaves a cancelled order cancelled" do
      order = create_order(status: :cancelled)

      described_class.new.handle(reserved_event(order))

      expect(Ticket.find(ticket_id)).to have_attributes(status: "reserved", version: 1)
      expect(order.reload).to be_cancelled
      expect(event_publisher).not_to have_received(:publish)
    end

    it "is a no-op when handled twice" do
      order = create_order
      described_class.new.handle(reserved_event(order))
      RSpec::Mocks.space.proxy_for(event_publisher).reset

      described_class.new.handle(reserved_event(order))

      expect(order.reload.lock_version).to eq(1)
      expect(event_publisher).not_to have_received(:publish)
    end

    it "refuses an event that skips a version and leaves the order Pending" do
      order = create_order

      expect { described_class.new.handle(reserved_event(order, version: 2)) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(order.reload).to be_created
    end

    it "ignores an order it does not know" do
      expect { described_class.new.handle(ticket_event(version: 1, status: "reserved").merge("order_id" => next_id)) }.not_to raise_error
      expect(Ticket.find(ticket_id).version).to eq(1)
    end
  end

  describe TicketReservationRejectedListener do
    before { TicketCreatedListener.new.handle(ticket_event(version: 0)) }

    def rejected_event(order) = { "id" => ticket_id, "order_id" => order.id, "reason" => "stale_version" }

    it "cancels the Pending order and publishes order:cancelled" do
      order = create_order

      described_class.new.handle(rejected_event(order))

      expect(order.reload).to be_cancelled
      expect(event_publisher).to have_received(:publish).with("order:cancelled", hash_including(id: order.id))
    end

    it "leaves an order that is already cancelled alone" do
      order = create_order(status: :cancelled)

      described_class.new.handle(rejected_event(order))

      expect(order.reload).to be_cancelled
      expect(event_publisher).not_to have_received(:publish)
    end

    it "leaves a paid order alone, as when an old order:created is replayed" do
      order = create_order(status: :complete)

      described_class.new.handle(rejected_event(order))

      expect(order.reload).to be_complete
      expect(event_publisher).not_to have_received(:publish)
    end

    it "ignores an order it does not know" do
      expect { described_class.new.handle("id" => ticket_id, "order_id" => next_id, "reason" => "unavailable") }.not_to raise_error
    end
  end

  describe PaymentCreatedListener do
    it "marks the order complete" do
      TicketCreatedListener.new.handle(ticket_event(version: 0))
      order = create_order(status: :awaiting_payment)

      described_class.new.handle("order_id" => order.id)

      expect(order.reload).to be_complete
    end

    it "does not revive a cancelled order" do
      TicketCreatedListener.new.handle(ticket_event(version: 0))
      order = create_order(status: :cancelled)

      described_class.new.handle("order_id" => order.id)

      expect(order.reload).to be_cancelled
    end
  end
end
