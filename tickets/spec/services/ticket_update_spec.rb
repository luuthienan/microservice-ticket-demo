require "rails_helper"

RSpec.describe TicketUpdate do
  let(:user_id) { next_id }
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id:) }

  def service(**overrides) = described_class.new({ ticket_id: ticket.id, user_id:, attributes: { title: "new" } }.merge(overrides))

  it "updates only the given attributes and publishes ticket:updated" do
    expect(service.call).to eq(ticket)

    expect(ticket.reload).to have_attributes(title: "new", price: 20)
    expect(event_publisher).to have_received(:publish).with("ticket:updated", hash_including(title: "new", version: 1))
  end

  it "does not publish when nothing changed" do
    service(attributes: { title: "concert" }).call

    expect(event_publisher).not_to have_received(:publish)
  end

  { reserved: { order_id: 1 }, sold: { order_id: 1 }, cancelled: {} }.each do |status, extra|
    it "fails with an error when the ticket is #{status}" do
      ticket.update!(status:, **extra)
      result = service

      expect(result.call).to be(false)
      expect(result.errors.full_messages).to eq(["Cannot edit a #{status} ticket"])
      expect(ticket.reload.title).to eq("concert")
    end
  end

  it "rejects a user who does not own the ticket" do
    expect { service(user_id: next_id).call }.to raise_error(ApiError::NotAuthorized)
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { service(ticket_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
