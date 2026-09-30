require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:user_id) { SecureRandom.uuid }
  let(:ticket) { Ticket.create!(title: "concert", price: 20) }

  def create_order(user_id: self.user_id, ticket: self.ticket)
    Order.create!(user_id:, ticket:, expires_at: 15.minutes.from_now)
  end

  describe "POST /api/orders" do
    it "requires sign in" do
      post "/api/orders", params: { ticketId: ticket.id }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for an unknown ticket" do
      post "/api/orders", params: { ticketId: SecureRandom.uuid }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "rejects a reserved ticket" do
      create_order(user_id: SecureRandom.uuid)

      post "/api/orders", params: { ticketId: ticket.id }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first["message"]).to eq("Ticket is already reserved")
    end

    it "creates an order and publishes order:created" do
      post "/api/orders", params: { ticketId: ticket.id }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:created)
      order = Order.last
      expect(order).to have_attributes(user_id:, status: "created", ticket:)
      expect(order.expires_at).to be_within(1.minute).of(15.minutes.from_now)
      expect(Events).to have_received(:publish).with("order:created", hash_including(id: order.id, version: 0))
    end
  end

  describe "GET /api/orders" do
    it "lists only the signed-in user's orders" do
      mine = create_order
      create_order(user_id: SecureRandom.uuid, ticket: Ticket.create!(title: "game", price: 10))

      get "/api/orders", headers: sign_in_as(user_id)

      expect(response.parsed_body.map { |o| o["id"] }).to eq([mine.id])
      expect(response.parsed_body.first["ticket"]).to include("title" => "concert")
    end
  end

  describe "GET /api/orders/:id" do
    it "returns the order" do
      order = create_order

      get "/api/orders/#{order.id}", headers: sign_in_as(user_id)

      expect(response.parsed_body).to include("id" => order.id, "status" => "created")
    end

    it "rejects another user's order" do
      get "/api/orders/#{create_order.id}", headers: sign_in_as

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for an unknown order" do
      get "/api/orders/#{SecureRandom.uuid}", headers: sign_in_as(user_id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/orders/:id" do
    it "cancels the order and publishes order:cancelled" do
      order = create_order

      delete "/api/orders/#{order.id}", headers: sign_in_as(user_id)

      expect(response).to have_http_status(:no_content)
      expect(order.reload).to be_cancelled
      expect(Events).to have_received(:publish)
        .with("order:cancelled", { id: order.id, version: 1, ticket: { id: ticket.id } })
    end

    it "rejects another user's order" do
      delete "/api/orders/#{create_order.id}", headers: sign_in_as

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 404 for an unknown order" do
      delete "/api/orders/#{SecureRandom.uuid}", headers: sign_in_as(user_id)

      expect(response).to have_http_status(:not_found)
    end
  end
end
