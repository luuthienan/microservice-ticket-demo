require "rails_helper"

RSpec.describe EventConsumer do
  let(:redis) { instance_spy(Redis) }
  let(:handled) { [] }
  let(:listener) do
    handled = self.handled
    Class.new do
      define_singleton_method(:subject) { "thing:happened" }
      define_method(:handle) { |data| handled << data }
    end
  end
  let(:consumer) { described_class.new("test-service", [listener]) }
  let(:entry) { ["1-0", { "data" => '{"id":1}' }] }

  before do
    allow(described_class).to receive(:redis).and_return(redis)
    allow(redis).to receive(:xautoclaim).and_return({ "entries" => [] })
    allow(redis).to receive(:xreadgroup).and_return({})
  end

  describe "#poll" do
    it "handles a fresh entry and acks it" do
      allow(redis).to receive(:xreadgroup).and_return({ "thing:happened" => [entry] })

      consumer.poll

      expect(handled).to eq([{ "id" => 1 }])
      expect(redis).to have_received(:xack).with("thing:happened", "test-service", "1-0")
    end

    it "redelivers stale entries and acks them" do
      allow(redis).to receive(:xautoclaim).and_return({ "entries" => [entry] })

      consumer.poll

      expect(handled).to eq([{ "id" => 1 }])
      expect(redis).to have_received(:xack).with("thing:happened", "test-service", "1-0")
    end

    it "does not ack an entry whose handler raises" do
      allow(redis).to receive(:xreadgroup).and_return({ "thing:happened" => [entry] })
      allow_any_instance_of(listener).to receive(:handle).and_raise("boom")

      expect { consumer.poll }.to output(/thing:happened 1-0 failed, will retry: RuntimeError: boom/).to_stderr
      expect(redis).not_to have_received(:xack)
    end
  end

  describe "#listen" do
    before { allow(consumer).to receive(:loop) }

    it "creates a consumer group for each subject" do
      consumer.listen

      expect(redis).to have_received(:xgroup).with(:create, "thing:happened", "test-service", "0", mkstream: true)
    end

    it "tolerates a group that already exists" do
      allow(redis).to receive(:xgroup).and_raise(Redis::CommandError, "BUSYGROUP Consumer Group name already exists")

      expect { consumer.listen }.not_to raise_error
    end

    it "re-raises other Redis errors" do
      allow(redis).to receive(:xgroup).and_raise(Redis::CommandError, "ERR boom")

      expect { consumer.listen }.to raise_error(Redis::CommandError, "ERR boom")
    end
  end
end
