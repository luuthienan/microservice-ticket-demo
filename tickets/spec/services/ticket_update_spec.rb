require "rails_helper"

RSpec.describe TicketUpdate do
  let(:user_id) { SecureRandom.uuid }
  let!(:ticket) { Ticket.create!(title: "concert", price: 20, user_id:) }

  def service(**overrides) = described_class.new({ ticket_id: ticket.id, user_id:, attributes: { title: "new" } }.merge(overrides))

  it "updates only the given attributes and publishes ticket:updated" do
    expect(service.call).to eq(ticket)

    expect(ticket.reload).to have_attributes(title: "new", price: 20)
    expect(Events).to have_received(:publish).with("ticket:updated", hash_including(title: "new", version: 1))
  end

  it "does not publish when nothing changed" do
    service(attributes: { title: "concert" }).call

    expect(Events).not_to have_received(:publish)
  end

  it "fails with an error when the ticket is reserved" do
    ticket.update!(order_id: SecureRandom.uuid)
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Cannot edit a reserved ticket"])
    expect(ticket.reload.title).to eq("concert")
  end

  it "rejects a user who does not own the ticket" do
    expect { service(user_id: SecureRandom.uuid).call }.to raise_error(ApiError::NotAuthorized)
  end

  it "raises RecordNotFound for an unknown ticket" do
    expect { service(ticket_id: SecureRandom.uuid).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
