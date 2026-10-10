require "rails_helper"

RSpec.describe Ticket do
  def create_ticket(**attrs) = Ticket.create!({ title: "concert", price: 20, user_id: next_id }.merge(attrs))

  it "starts out available without an order" do
    expect(create_ticket).to have_attributes(status: "available", order_id: nil)
  end

  it "needs an order for a reserved or sold ticket" do
    %i[reserved sold].each do |status|
      expect { create_ticket(status:) }.to raise_error(ActiveRecord::StatementInvalid, /tickets_order_id_matches_status/)
    end
  end

  it "has no order when available or cancelled" do
    %i[available cancelled].each do |status|
      expect { create_ticket(status:, order_id: next_id) }
        .to raise_error(ActiveRecord::StatementInvalid, /tickets_order_id_matches_status/)
    end
  end

  it "rejects an unknown status" do
    expect { create_ticket(status: "lost") }.to raise_error(ArgumentError, /not a valid status/)
  end
end
