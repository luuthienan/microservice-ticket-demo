require "rails_helper"

RSpec.describe OrderCreatedListener do
  it "schedules an expiration job at the order's expiry time" do
    expires_at = 15.minutes.from_now.change(usec: 0)
    allow(ExpireOrderJob).to receive(:perform_at)

    described_class.new.handle("id" => "order-1", "expires_at" => expires_at.iso8601)

    expect(ExpireOrderJob).to have_received(:perform_at).with(expires_at, "order-1")
  end
end
