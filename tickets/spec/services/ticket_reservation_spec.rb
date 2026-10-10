require "rails_helper"

RSpec.describe TicketReservation do
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id: next_id) }
  let(:order_id) { next_id }

  def call(order_id: self.order_id, version: ticket.lock_version) = described_class.new(ticket_id: ticket.id, order_id:, version:).call

  def expect_rejected(reason, order_id: self.order_id)
    expect(event_publisher).to have_received(:publish)
      .with("ticket:reservation-rejected", { id: ticket.id, order_id:, reason: })
    expect(event_publisher).not_to have_received(:publish).with("ticket:reserved", anything)
  end

  it "reserves the ticket for the order and publishes ticket:reserved with the new version" do
    call

    expect(ticket.reload).to have_attributes(status: "reserved", order_id:)
    expect(event_publisher).to have_received(:publish)
      .with("ticket:reserved", hash_including(id: ticket.id, title: "concert", price: 20, order_id:, status: "reserved", version: 1))
    expect(event_publisher).not_to have_received(:publish).with("ticket:updated", anything)
  end

  it "rejects the reservation when the ticket was edited after the order was placed" do
    version = ticket.lock_version
    ticket.update!(price: 25)

    call(version:)

    expect(ticket.reload).to have_attributes(status: "available", order_id: nil, price: 25)
    expect_rejected(:stale_version)
  end

  it "rejects the reservation when the ticket changed between reading it and reserving it" do
    allow(Ticket).to receive(:find).and_wrap_original do |find, *args|
      find.call(*args).tap { Ticket.where(id: ticket.id).update_all("price = 25, lock_version = lock_version + 1") } # a seller's edit lands right after the read
    end

    call

    expect(ticket.reload).to have_attributes(status: "available", price: 25)
    expect_rejected(:stale_version)
  end

  it "rejects the reservation of a ticket held by another order, as when an old order:created is replayed" do
    held_by = next_id
    ticket.update!(status: :reserved, order_id: held_by)

    call

    expect(ticket.reload).to have_attributes(status: "reserved", order_id: held_by)
    expect_rejected(:unavailable)
  end

  it "rejects the reservation of a sold ticket" do
    sold_to = next_id
    ticket.update!(status: :sold, order_id: sold_to)

    call

    expect(ticket.reload).to have_attributes(status: "sold", order_id: sold_to)
    expect_rejected(:unavailable)
  end

  it "rejects the reservation of a cancelled ticket" do
    ticket.update!(status: :cancelled)

    call

    expect(ticket.reload).to have_attributes(status: "cancelled", order_id: nil)
    expect_rejected(:unavailable)
  end

  it "rejects an old order whose version no longer matches after another order reserved and released the ticket" do
    version = ticket.lock_version
    ticket.update!(status: :reserved, order_id: next_id)
    ticket.update!(status: :available, order_id: nil)

    call(version:)

    expect_rejected(:stale_version)
  end

  it "does nothing when the order already holds the ticket, as when order:created is replayed" do
    version = ticket.lock_version
    call
    RSpec::Mocks.space.proxy_for(event_publisher).reset

    call(version:)

    expect(ticket.reload).to have_attributes(status: "reserved", order_id:, lock_version: 1)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "does nothing when the order already holds the ticket as sold" do
    ticket.update!(status: :sold, order_id:)

    call(version: 0)

    expect(event_publisher).not_to have_received(:publish)
  end

  describe "when a seller edits the ticket as an order reserves it" do
    self.use_transactional_tests = false

    after { Ticket.where(id: ticket.id).delete_all }

    it "lets exactly one of them win" do
      version = ticket.lock_version
      order_id # memoize `let`s before the threads read them
      start = Queue.new
      reservation = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          start.pop
          call(version:)
        end
      end
      edit = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          start.pop
          TicketUpdate.new(ticket_id: ticket.id, user_id: ticket.user_id, attributes: { price: 25 }).call
        rescue ActiveRecord::StaleObjectError
          :lost
        end
      end
      2.times { start << :go }
      [reservation, edit].each(&:join)

      ticket.reload
      if ticket.reserved?
        expect(ticket).to have_attributes(price: 20, order_id:)
      else
        expect(ticket).to have_attributes(status: "available", price: 25)
        expect(event_publisher).to have_received(:publish).with("ticket:reservation-rejected", hash_including(order_id:))
      end
    end
  end
end
