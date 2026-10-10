require "rails_helper"

RSpec.describe "Payments", type: :request do
  let(:user_id) { next_id }
  let(:order) { Order.create!(id: next_id, user_id:, price: 20.5, status: :awaiting_payment) }

  before { allow(Stripe::Charge).to receive(:create).and_return(double(id: "ch_123")) }

  def pay(order_id: order.id, user: user_id)
    post "/api/v1/payments", params: { order_id: order_id, token: "tok_visa" }, headers: sign_in_as(user), as: :json
  end

  it "requires sign in" do
    post "/api/v1/payments", params: { order_id: order.id, token: "tok_visa" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a token whose id claim is not an integer" do
    pay(user: SecureRandom.uuid)

    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 404 for an unknown order" do
    pay(order_id: next_id)

    expect(response).to have_http_status(:not_found)
  end

  it "rejects another user's order" do
    pay(user: next_id)

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a missing order_id or token" do
    post "/api/v1/payments", params: {}, headers: sign_in_as(user_id), as: :json

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["errors"].map { |e| e["field"] }).to eq(%w[order_id token])
    expect(Stripe::Charge).not_to have_received(:create)
  end

  it "rejects a cancelled order" do
    order.cancelled!

    pay

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["errors"].first["message"]).to eq("Cannot pay for a cancelled order")
  end

  it "rejects an order that is already paid" do
    pay
    pay

    expect(response).to have_http_status(:bad_request)
    expect(Payment.count).to eq(1)
  end

  it "returns the card error message and saves nothing when the card is declined" do
    allow(Stripe::Charge).to receive(:create)
      .and_raise(Stripe::CardError.new("Your card was declined.", "number", code: "card_declined"))

    pay

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["errors"]).to eq([{ "message" => "Your card was declined." }])
    expect(Payment.count).to eq(0)
  end

  it "charges the card, saves the payment and publishes payment:created" do
    pay

    expect(response).to have_http_status(:created)
    expect(Stripe::Charge).to have_received(:create).with(hash_including(amount: 2050, currency: "usd", source: "tok_visa"))
    payment = Payment.last
    expect(payment).to have_attributes(order:, stripe_id: "ch_123")
    expect(response.parsed_body).to eq("id" => payment.id)
    expect(event_publisher).to have_received(:publish)
      .with("payment:created", { id: payment.id, order_id: order.id, stripe_id: "ch_123" })
  end
end
