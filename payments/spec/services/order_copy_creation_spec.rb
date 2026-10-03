require "rails_helper"

RSpec.describe OrderCopyCreation do
  it "stores a copy of the order" do
    id = SecureRandom.uuid

    described_class.new(id:, user_id: SecureRandom.uuid, status: "created", price: 20, version: 0).call

    expect(Order.find(id)).to have_attributes(status: "created", price: 20, version: 0)
  end
end
