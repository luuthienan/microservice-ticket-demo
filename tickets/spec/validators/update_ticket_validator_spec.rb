require "rails_helper"

RSpec.describe UpdateTicketValidator do
  it "is valid when nothing is given" do
    expect(described_class.new({})).to be_valid
  end

  it "validates only the attributes that are present" do
    expect(described_class.new(title: "new")).to be_valid
    expect(described_class.new(price: 5)).to be_valid
  end

  it "rejects a given blank title or non-positive price" do
    expect(described_class.new(title: "")).not_to be_valid
    expect(described_class.new(title: nil)).not_to be_valid
    expect(described_class.new(price: -1)).not_to be_valid
  end
end
