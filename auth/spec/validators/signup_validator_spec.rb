require "rails_helper"

RSpec.describe SignupValidator do
  it "is valid with a well-formed email and a 4..20 character password" do
    expect(described_class.new(email: "test@test.com", password: "password")).to be_valid
  end

  it "validates the email as it will be stored (trimmed, downcased)" do
    validator = described_class.new(email: "  Test@Test.com ", password: "password")

    expect(validator).to be_valid
    expect(validator.email).to eq("test@test.com")
  end

  it "rejects an invalid email" do
    validator = described_class.new(email: "nope", password: "password")

    expect(validator).not_to be_valid
    expect(validator.errors.full_messages).to eq(["Email must be valid"])
  end

  it "rejects a missing email" do
    expect(described_class.new(email: nil, password: "password")).not_to be_valid
  end

  it "requires a password" do
    [nil, ""].each do |password|
      validator = described_class.new(email: "test@test.com", password:)

      expect(validator).not_to be_valid
      expect(validator.errors.full_messages).to eq(["Password can't be blank"])
    end
  end

  it "rejects a password outside 4..20 characters" do
    %w[abc] .push("a" * 21).each do |password|
      expect(described_class.new(email: "test@test.com", password:)).not_to be_valid
    end
  end
end
