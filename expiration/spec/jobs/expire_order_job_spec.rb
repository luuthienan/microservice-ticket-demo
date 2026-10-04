require "rails_helper"

RSpec.describe ExpireOrderJob do
  it "publishes expiration:complete" do
    described_class.new.perform("order-1")

    expect(event_publisher).to have_received(:publish).with("expiration:complete", { order_id: "order-1" })
  end
end
