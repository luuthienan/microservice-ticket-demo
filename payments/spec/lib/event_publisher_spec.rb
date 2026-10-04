require "rails_helper"

RSpec.describe EventPublisher do
  let(:redis) { instance_spy(Redis) }

  before do
    allow(EventPublisher).to receive(:new).and_call_original
    allow(EventPublisher).to receive(:redis).and_return(redis)
  end

  it "adds the data as JSON to the stream named by the subject" do
    described_class.new.publish("ticket:created", { id: 1, title: "concert" })

    expect(redis).to have_received(:xadd).with("ticket:created", { data: '{"id":1,"title":"concert"}' })
  end
end
