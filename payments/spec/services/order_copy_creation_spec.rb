require "rails_helper"

RSpec.describe OrderCopyCreation do
  it "stores a copy of the order" do
    id = next_id

    described_class.new(id:, user_id: next_id, status: "created", price: 20, version: 0).call

    expect(Order.find(id)).to have_attributes(status: "created", price: 20, version: 0)
  end

  it "keeps the copy as it is when the event is delivered again" do
    id = next_id
    attributes = { id:, user_id: next_id, status: "created", price: 20, version: 0 }
    described_class.new(**attributes).call
    Order.find(id).update!(status: :cancelled, version: 1)

    expect { described_class.new(**attributes).call }.not_to raise_error

    expect(Order.find(id)).to have_attributes(status: "cancelled", version: 1)
  end
end
