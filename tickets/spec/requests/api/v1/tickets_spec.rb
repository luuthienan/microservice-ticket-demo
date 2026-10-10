require "rails_helper"

RSpec.describe "Tickets", type: :request do
  let(:user_id) { next_id }

  def create_ticket(user_id: self.user_id, **attrs)
    Ticket.create!({ title: "concert", price: 20, user_id: }.merge(attrs))
  end

  describe "GET /api/v1/tickets" do
    it "lists tickets without signing in" do
      create_ticket
      create_ticket(title: "game")

      get "/api/v1/tickets"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end
  end

  describe "GET /api/v1/tickets/mine" do
    it "requires sign in" do
      get "/api/v1/tickets/mine"

      expect(response).to have_http_status(:unauthorized)
    end

    it "lists only the caller's tickets, whatever their status" do
      mine = Ticket.statuses.keys.map { |status| create_ticket(status:) }
      create_ticket(user_id: next_id)

      get "/api/v1/tickets/mine", headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |t| t["id"] }).to match_array(mine.map(&:id))
      expect(response.parsed_body.map { |t| t["status"] }).to match_array(%w[available reserved sold cancelled])
    end

    it "lists the newest ticket first" do
      older = create_ticket(created_at: 2.days.ago)
      newer = create_ticket(created_at: 1.day.ago)

      get "/api/v1/tickets/mine", headers: sign_in_as(user_id), as: :json

      expect(response.parsed_body.map { |t| t["id"] }).to eq([newer.id, older.id])
    end
  end

  describe "GET /api/v1/tickets/:id" do
    it "returns the ticket" do
      ticket = create_ticket

      get "/api/v1/tickets/#{ticket.id}"

      expect(response.parsed_body).to include("title" => "concert", "price" => "20.00", "user_id" => user_id, "status" => "available")
    end

    it "returns 404 for an unknown ticket" do
      get "/api/v1/tickets/#{next_id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/tickets" do
    it "requires sign in" do
      post "/api/v1/tickets", params: { title: "concert", price: 10 }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a token whose id claim is not an integer" do
      post "/api/v1/tickets", params: { title: "concert", price: 10 }, headers: sign_in_as(SecureRandom.uuid), as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an empty title" do
      post "/api/v1/tickets", params: { title: "", price: 10 }, headers: sign_in_as, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects a price that is not positive" do
      post "/api/v1/tickets", params: { title: "concert", price: -10 }, headers: sign_in_as, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it "creates the ticket and publishes ticket:created" do
      post "/api/v1/tickets", params: { title: "concert", price: 10 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:created)
      expect(Ticket.last).to have_attributes(title: "concert", user_id:)
      expect(event_publisher).to have_received(:publish).with("ticket:created", hash_including(title: "concert"))
    end
  end

  describe "PUT /api/v1/tickets/:id" do
    let!(:ticket) { create_ticket }

    it "returns 404 for an unknown ticket" do
      put "/api/v1/tickets/#{next_id}", params: { title: "a", price: 1 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "requires sign in" do
      put "/api/v1/tickets/#{ticket.id}", params: { title: "a", price: 1 }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects a user who does not own the ticket" do
      put "/api/v1/tickets/#{ticket.id}", params: { title: "a", price: 1 }, headers: sign_in_as, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects invalid input" do
      put "/api/v1/tickets/#{ticket.id}", params: { title: "", price: -1 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects editing a reserved ticket" do
      ticket.update!(status: :reserved, order_id: next_id)

      put "/api/v1/tickets/#{ticket.id}", params: { title: "a", price: 1 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first["message"]).to eq("Cannot edit a reserved ticket")
    end

    it "answers 409 when a reservation wins the race" do
      allow_any_instance_of(Ticket).to receive(:update!).and_raise(ActiveRecord::StaleObjectError)

      put "/api/v1/tickets/#{ticket.id}", params: { title: "new", price: 99 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:conflict)
    end

    it "updates the ticket and publishes ticket:updated" do
      put "/api/v1/tickets/#{ticket.id}", params: { title: "new", price: 99 }, headers: sign_in_as(user_id), as: :json

      expect(response).to have_http_status(:ok)
      expect(ticket.reload).to have_attributes(title: "new", price: 99)
      expect(event_publisher).to have_received(:publish).with("ticket:updated", hash_including(title: "new", version: 1))
    end
  end
end
