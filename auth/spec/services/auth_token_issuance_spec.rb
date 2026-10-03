require "rails_helper"

RSpec.describe AuthTokenIssuance do
  it "signs a token carrying the user and a one-day expiry" do
    user = User.create!(email: "test@test.com", password: "password")
    service = described_class.new(user:)

    payload, = JWT.decode(service.call, ENV.fetch("JWT_KEY"), true, algorithm: "HS256")

    expect(payload).to include("id" => user.id, "email" => "test@test.com", "exp" => service.expires_at.to_i)
    expect(service.expires_at).to be_within(1.minute).of(1.day.from_now)
  end
end
