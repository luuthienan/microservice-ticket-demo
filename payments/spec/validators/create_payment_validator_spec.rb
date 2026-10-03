require "rails_helper"

RSpec.describe CreatePaymentValidator do
  it "is valid with an order id and a token" do
    expect(described_class.new(order_id: SecureRandom.uuid, token: "tok_visa")).to be_valid
  end

  it "requires both" do
    validator = described_class.new(order_id: nil, token: "")

    expect(validator).not_to be_valid
    expect(validator.errors.map(&:attribute)).to eq(%i[order_id token])
  end
end
