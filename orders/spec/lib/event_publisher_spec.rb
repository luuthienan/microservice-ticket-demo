require "rails_helper"

RSpec.describe EventPublisher do
  before { allow(EventPublisher).to receive(:new).and_call_original }

  it "records the event in the outbox, keyed by the entity's id" do
    described_class.new.publish("ticket:updated", { id: 7, order_id: 9, title: "concert" })

    expect(OutboxEvent.last).to have_attributes(
      subject: "ticket:updated", entity_id: 7, payload: { "id" => 7, "order_id" => 9, "title" => "concert" }, published_at: nil
    )
  end

  %w[payment:requested payment:paid payment:failed].each do |subject|
    it "keys #{subject} by its order, so all events for an order stay in order" do
      described_class.new.publish(subject, { id: 3, order_id: 5 })

      expect(OutboxEvent.last.entity_id).to eq(5)
    end
  end

  it "raises outside a transaction, so the event can't outlive a rolled-back change" do
    allow(OutboxEvent.connection).to receive(:transaction_open?).and_return(false)

    expect { described_class.new.publish("ticket:created", { id: 1 }) }.to raise_error(/inside the transaction/)
    expect(OutboxEvent.count).to eq(0)
  end

  it "raises for a subject that has no topic" do
    expect { described_class.new.publish("nonsense:happened", { id: 1 }) }.to raise_error(KeyError)
  end
end
