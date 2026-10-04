require "rails_helper"

RSpec.describe EventConsumer do
  include ActiveSupport::Testing::TimeHelpers

  Message = Struct.new(:topic, :partition, :offset, :key, :payload, :headers)

  let(:kafka) { instance_spy(Rdkafka::Consumer) }
  let(:handle) { instance_double(Rdkafka::Producer::DeliveryHandle, wait: nil) }
  let(:producer) { instance_spy(Rdkafka::Producer, produce: handle) }
  let(:handled) { [] }
  let(:listener) do
    handled = self.handled
    Class.new do
      define_singleton_method(:subject) { "ticket:created" }
      define_method(:handle) { |data| handled << data }
    end
  end
  let(:consumer) { described_class.new("test-service", [listener], consumer: kafka, producer:) }

  def message(offset: 5, subject: "ticket:created", payload: '{"id":1}')
    Message.new("tickets.events", 2, offset, "1", payload, { "subject" => subject, "event_id" => "10" })
  end

  def deliver(msg)
    allow(kafka).to receive(:poll).and_return(msg)
    consumer.poll
  end

  it "reads the topics its listeners' subjects live on" do
    expect(consumer.topics).to eq(["tickets.events"])
  end

  describe "#poll" do
    it "handles a message and commits its offset" do
      msg = message

      deliver(msg)

      expect(handled).to eq([{ "id" => 1 }])
      expect(kafka).to have_received(:store_offset).with(msg)
      expect(kafka).to have_received(:commit)
    end

    it "does nothing when there is no message" do
      deliver(nil)

      expect(kafka).not_to have_received(:commit)
    end

    it "commits past a subject it has no listener for without handling it" do
      deliver(message(subject: "ticket:updated"))

      expect(handled).to be_empty
      expect(kafka).to have_received(:commit)
    end

    context "when the handler fails" do
      let(:listener) do
        Class.new do
          def self.subject = "ticket:created"
          def handle(_data) = raise("boom")
        end
      end

      before { allow(consumer).to receive(:warn) }

      it "rewinds to the message and pauses only its partition instead of committing" do
        msg = message

        deliver(msg)

        expect(kafka).to have_received(:seek).with(msg)
        expect(kafka).to have_received(:pause)
        expect(kafka).not_to have_received(:commit)
        expect(producer).not_to have_received(:produce)
      end

      it "resumes the partition once the backoff has passed" do
        deliver(message)
        allow(kafka).to receive(:poll).and_return(nil)
        consumer.poll
        expect(kafka).not_to have_received(:resume)

        travel(2.seconds) { consumer.poll }

        expect(kafka).to have_received(:resume)
      end

      it "dead-letters the message after the fifth failure and moves on" do
        msg = message(offset: 9)
        allow(kafka).to receive(:poll).and_return(msg)
        5.times { consumer.poll }

        expect(kafka).to have_received(:pause).exactly(4).times
        expect(producer).to have_received(:produce).with(
          topic: "tickets.events.dlt", key: "1", payload: '{"id":1}',
          headers: { "subject" => "ticket:created", "event_id" => "10", "error" => "RuntimeError: boom", "attempts" => "5",
                     "original_topic" => "tickets.events", "original_partition" => "2", "original_offset" => "9" }
        )
        expect(kafka).to have_received(:store_offset).with(msg)
        expect(kafka).to have_received(:commit)
      end

      it "counts attempts per message" do
        allow(kafka).to receive(:poll).and_return(message(offset: 1), message(offset: 2))
        2.times { consumer.poll }

        expect(kafka).to have_received(:pause).twice
      end
    end

    it "treats a payload that is not JSON like any other failing handler" do
      allow(consumer).to receive(:warn)

      deliver(message(payload: "not json"))

      expect(kafka).to have_received(:pause)
      expect(kafka).not_to have_received(:commit)
    end
  end
end
