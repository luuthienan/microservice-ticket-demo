require "rails_helper"

RSpec.describe "listeners" do
  let(:ticket_id) { next_id }

  def ticket_event(version:, title: "concert", price: 20)
    { "id" => ticket_id, "title" => title, "price" => price, "version" => version }
  end

  def create_order(status: :created)
    Order.create!(user_id: next_id, ticket: Ticket.find(ticket_id), status:, expires_at: 15.minutes.from_now)
  end

  describe TicketCreatedListener do
    it "stores a copy of the ticket" do
      described_class.new.handle(ticket_event(version: 0))

      expect(Ticket.find(ticket_id)).to have_attributes(title: "concert", price: 20, version: 0)
    end
  end

  describe TicketUpdatedListener do
    before { TicketCreatedListener.new.handle(ticket_event(version: 0)) }

    it "applies the next version" do
      described_class.new.handle(ticket_event(version: 1, title: "new", price: 99))

      expect(Ticket.find(ticket_id)).to have_attributes(title: "new", price: 99, version: 1)
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

  describe PaymentCreatedListener do
    it "marks the order complete" do
      TicketCreatedListener.new.handle(ticket_event(version: 0))
      order = create_order

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
