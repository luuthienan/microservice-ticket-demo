require "rails_helper"

RSpec.describe UserRegistration do
  it "creates the user with a hashed password" do
    user = described_class.new(email: "test@test.com", password: "password").call

    expect(user).to be_persisted
    expect(user.authenticate("password")).to eq(user)
  end

  it "fails with an error when the email is in use" do
    described_class.new(email: "test@test.com", password: "password").call
    service = described_class.new(email: "test@test.com", password: "password")

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Email in use"])
    expect(User.count).to eq(1)
  end

  it "treats a unique-index violation as email in use" do
    allow(User).to receive(:exists?).and_return(false)
    allow(User).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
    service = described_class.new(email: "test@test.com", password: "password")

    expect(service.call).to be(false)
    expect(service.errors.full_messages).to eq(["Email in use"])
  end
end
