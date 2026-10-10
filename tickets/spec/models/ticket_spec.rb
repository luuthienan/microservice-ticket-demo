require "rails_helper"

RSpec.describe Ticket do
  def create_ticket(**attrs) = Ticket.create!({ title: "concert", price: 20, user_id: next_id }.merge(attrs))

  it "starts out available without an order" do
    expect(create_ticket).to have_attributes(status: "available", order_id: nil)
  end

  it "rejects an unknown status" do
    expect { create_ticket(status: "lost") }.to raise_error(ArgumentError, /not a valid status/)
  end
end
