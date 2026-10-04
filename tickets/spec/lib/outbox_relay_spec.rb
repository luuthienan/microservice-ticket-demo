require "rails_helper"

RSpec.describe OutboxRelay do
  let(:handle) { instance_double(Rdkafka::Producer::DeliveryHandle, wait: nil) }
  let(:producer) { instance_double(Rdkafka::Producer, produce: handle) }
  let(:relay) { described_class.new(producer:) }

  def outbox(subject, entity_id, payload = { id: entity_id })
    OutboxEvent.create!(subject:, entity_id:, payload:, occurred_at: Time.utc(2026, 10, 4, 9))
  end

  describe "#relay_pending" do
    it "produces each event to its topic with the entity id as key and the metadata as headers" do
      event = outbox("ticket:created", 7, { id: 7, title: "concert" })

      expect(relay.relay_pending).to eq(1)

      expect(producer).to have_received(:produce).with(
        topic: "tickets.events", key: "7", payload: '{"id":7,"title":"concert"}',
        headers: { "subject" => "ticket:created", "event_id" => event.id.to_s,
                   "occurred_at" => "2026-10-04T09:00:00.000Z", "producer" => EventBus.producer_name }
      )
      expect(event.reload.published_at).to be_present
    end

    it "sends events in id order and skips ones already published" do
      done = outbox("ticket:created", 1).tap { |event| event.update!(published_at: Time.current) }
      first = outbox("ticket:created", 2)
      second = outbox("ticket:updated", 2)

      sent = []
      allow(producer).to receive(:produce) { |headers:, **| sent << headers["event_id"].to_i && handle }

      relay.relay_pending

      expect(sent).to eq([first.id, second.id])
      expect(done.reload.published_at).to be_present
    end

    it "stops at an event Kafka did not accept and leaves it, and the ones after it, unpublished" do
      first = outbox("ticket:created", 1)
      second = outbox("ticket:created", 2)
      third = outbox("ticket:created", 3)
      failing = instance_double(Rdkafka::Producer::DeliveryHandle)
      allow(failing).to receive(:wait).and_raise(Rdkafka::RdkafkaError.new(-185))
      allow(producer).to receive(:produce).and_return(handle, failing)

      expect { relay.relay_pending }.to raise_error(Rdkafka::RdkafkaError)

      expect(first.reload.published_at).to be_present
      expect(second.reload.published_at).to be_nil
      expect(third.reload.published_at).to be_nil
      expect(producer).to have_received(:produce).twice
    end

    it "does nothing when the outbox is empty" do
      expect(relay.relay_pending).to eq(0)
      expect(producer).not_to have_received(:produce)
    end
  end

  describe "#purge_published" do
    include ActiveSupport::Testing::TimeHelpers

    it "deletes events published more than a week ago, once an hour" do
      old = outbox("ticket:created", 1).tap { |event| event.update!(published_at: 8.days.ago) }
      recent = outbox("ticket:created", 2).tap { |event| event.update!(published_at: 1.day.ago) }
      pending = outbox("ticket:created", 3)

      relay.purge_published
      expect(OutboxEvent.exists?(old.id)).to be(true)

      travel(2.hours) { relay.purge_published }

      expect(OutboxEvent.exists?(old.id)).to be(false)
      expect(OutboxEvent.exists?(recent.id)).to be(true)
      expect(OutboxEvent.exists?(pending.id)).to be(true)
    end
  end
end
