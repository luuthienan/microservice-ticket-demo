require "rails_helper"

RSpec.describe "Users", type: :request do
  def signup(email: "test@test.com", password: "password")
    post "/api/v1/users/signup", params: { email:, password: }, as: :json
  end

  describe "POST /api/v1/users/signup" do
    it "creates a user and sets the jwt cookie" do
      signup

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("email" => "test@test.com")
      expect(response.parsed_body).not_to have_key("password_digest")
      expect(response.headers["Set-Cookie"]).to include("jwt=")
    end

    it "rejects an invalid email" do
      signup(email: "nope")

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first["field"]).to eq("email")
    end

    it "rejects a short password" do
      signup(password: "abc")

      expect(response).to have_http_status(:bad_request)
    end

    it "rejects a duplicate email" do
      signup
      signup

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first["message"]).to eq("Email in use")
    end
  end

  describe "POST /api/v1/users/signin" do
    before { signup }

    it "signs in with valid credentials" do
      post "/api/v1/users/signin", params: { email: "test@test.com", password: "password" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.keys).to match_array(%w[id email])
      expect(response.headers["Set-Cookie"]).to include("jwt=")
    end

    it "rejects a wrong password" do
      post "/api/v1/users/signin", params: { email: "test@test.com", password: "wrong" }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first["message"]).to eq("Invalid credentials")
    end

    it "rejects an unknown email" do
      post "/api/v1/users/signin", params: { email: "x@test.com", password: "password" }, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/v1/users/signout" do
    it "clears the jwt cookie" do
      post "/api/v1/users/signout"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Set-Cookie"]).to include("jwt=;")
    end

    it "expires the cookie on the same path it was set on" do
      signup
      set_path = response.headers["Set-Cookie"][/path=[^;]+/i]
      post "/api/v1/users/signout"

      expect(response.headers["Set-Cookie"][/path=[^;]+/i]).to eq(set_path)
    end
  end

  describe "GET /api/v1/users/currentuser" do
    it "returns the signed-in user" do
      signup
      get "/api/v1/users/currentuser"

      expect(response.parsed_body["current_user"]).to include("email" => "test@test.com")
      expect(response.parsed_body["current_user"]).not_to have_key("password_digest")
    end

    it "returns null when signed out" do
      get "/api/v1/users/currentuser"

      expect(response.parsed_body).to eq("current_user" => nil)
    end
  end
end
