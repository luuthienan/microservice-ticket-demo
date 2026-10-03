require "rails_helper"

RSpec.describe SigninValidator do
  it "is valid with an email and a password" do
    expect(described_class.new(email: "test@test.com", password: "x")).to be_valid
  end

  it "requires both" do
    validator = described_class.new(email: "", password: nil)

    expect(validator).not_to be_valid
    expect(validator.errors.map(&:attribute)).to eq(%i[email password])
  end
end
