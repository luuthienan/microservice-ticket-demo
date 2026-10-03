require "rails_helper"

RSpec.describe CreateOrderValidator do
  it "is valid with a ticket id" do
    expect(described_class.new(ticket_id: SecureRandom.uuid)).to be_valid
  end

  it "requires a ticket id" do
    validator = described_class.new(ticket_id: nil)

    expect(validator).not_to be_valid
    expect(validator.errors.map(&:attribute)).to eq([:ticket_id])
  end
end
