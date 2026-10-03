require "rails_helper"

RSpec.describe CreateTicketValidator do
  it "is valid with a title and a positive price" do
    expect(described_class.new(title: "concert", price: 10)).to be_valid
  end

  it "requires a title" do
    validator = described_class.new(title: "", price: 10)

    expect(validator).not_to be_valid
    expect(validator.errors.map(&:attribute)).to eq([:title])
  end

  it "requires a positive numeric price" do
    [nil, 0, -1, "abc"].each do |price|
      validator = described_class.new(title: "concert", price:)

      expect(validator).not_to be_valid
      expect(validator.errors.map(&:attribute)).to eq([:price])
    end
  end
end
