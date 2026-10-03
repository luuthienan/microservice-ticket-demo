require "rails_helper"

RSpec.describe PaymentCreation do
  let(:user_id) { next_id }
  let(:order) { Order.create!(id: next_id, user_id:, price: 20.5, status: :created) }

  before { allow(Stripe::Charge).to receive(:create).and_return(double(id: "ch_123")) }

  def service(**overrides) = described_class.new({ order_id: order.id, token: "tok_visa", user_id: }.merge(overrides))

  it "charges the card, saves the payment and publishes payment:created" do
    payment = service.call

    expect(Stripe::Charge).to have_received(:create)
      .with(amount: 2050, currency: "usd", source: "tok_visa", description: "Order #{order.id}")
    expect(payment).to have_attributes(order:, stripe_id: "ch_123")
    expect(Events).to have_received(:publish)
      .with("payment:created", { id: payment.id, order_id: order.id, stripe_id: "ch_123" })
  end

  it "fails with an error for a cancelled order" do
    order.cancelled!
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Cannot pay for a cancelled order"])
    expect(Stripe::Charge).not_to have_received(:create)
  end

  it "fails with an error for an order that is already paid" do
    service.call
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Order is already paid"])
    expect(Payment.count).to eq(1)
  end

  it "rejects another user's order before charging" do
    expect { service(user_id: next_id).call }.to raise_error(ApiError::NotAuthorized)
    expect(Stripe::Charge).not_to have_received(:create)
  end

  it "raises RecordNotFound for an unknown order" do
    expect { service(order_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "lets a declined card propagate and saves nothing" do
    allow(Stripe::Charge).to receive(:create)
      .and_raise(Stripe::CardError.new("Your card was declined.", "number", code: "card_declined"))

    expect { service.call }.to raise_error(Stripe::CardError)
    expect(Payment.count).to eq(0)
  end
end
