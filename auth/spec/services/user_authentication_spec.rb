require "rails_helper"

RSpec.describe UserAuthentication do
  let!(:user) { User.create!(email: "test@test.com", password: "password") }

  it "returns the user for valid credentials" do
    expect(described_class.new(email: "Test@Test.com", password: "password").call).to eq(user)
  end

  it "fails with an error for a wrong password or unknown email" do
    [%w[test@test.com wrong], %w[x@test.com password]].each do |email, password|
      service = described_class.new(email:, password:)

      expect(service.call).to be(false)
      expect(service.errors.full_messages).to eq(["Invalid credentials"])
    end
  end
end
