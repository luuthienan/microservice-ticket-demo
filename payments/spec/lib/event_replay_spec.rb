require "rails_helper"

RSpec.describe EventReplay do
  let(:kafka) do
    instance_double(
      Rdkafka::Consumer, close: nil, commit: nil,
      metadata: double(topics: [{ partitions: [{ partition_id: 0 }, { partition_id: 1 }] }])
    )
  end

  def committed
    committed = nil
    expect(kafka).to have_received(:commit) { |list, _async| committed = list.to_h }
    committed
  end

  it "rewinds every partition to the earliest offset" do
    allow(kafka).to receive(:query_watermark_offsets).with("tickets.events", 0).and_return([3, 40])
    allow(kafka).to receive(:query_watermark_offsets).with("tickets.events", 1).and_return([0, 12])

    described_class.new("tickets-service", ["tickets.events"], from: "earliest", consumer: kafka).call

    offsets = committed.fetch("tickets.events").to_h { |tp| [tp.partition, tp.offset] }
    expect(offsets).to eq(0 => 3, 1 => 0)
    expect(kafka).to have_received(:close)
  end

  it "rewinds one partition to a given offset" do
    described_class.new("tickets-service", ["tickets.events"], from: "offset:1:7", consumer: kafka).call

    offsets = committed.fetch("tickets.events").to_h { |tp| [tp.partition, tp.offset] }
    expect(offsets).to eq(1 => 7)
  end

  it "rejects a FROM it does not understand, and still closes the consumer" do
    expect { described_class.new("tickets-service", ["tickets.events"], from: "yesterday", consumer: kafka).call }
      .to raise_error(ArgumentError, /FROM must be/)
    expect(kafka).to have_received(:close)
    expect(kafka).not_to have_received(:commit)
  end
end
