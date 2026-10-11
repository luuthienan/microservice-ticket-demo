require "rails_helper"

RSpec.describe PaymentCreation do
  let(:user_id) { next_id }
  let(:order) { Order.create!(id: next_id, user_id:, price: 20.5, status: :awaiting_payment) }

  before { allow(Stripe::Charge).to receive(:create) }

  def service(**overrides) = described_class.new({ order_id: order.id, token: "tok_visa", user_id: }.merge(overrides))

  it "saves a pending payment with the token and asks orders to claim the order, without charging the card" do
    payment = service.call

    expect(payment).to have_attributes(order:, status: "pending", token: "tok_visa", stripe_id: nil)
    expect(event_publisher).to have_received(:publish).with("payment:requested", { id: payment.id, order_id: order.id })
    expect(Stripe::Charge).not_to have_received(:create)
  end

  it "fails with an error for a cancelled order" do
    order.cancelled!
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Cannot pay for a cancelled order"])
    expect(Payment.count).to eq(0)
    expect(event_publisher).not_to have_received(:publish)
  end

  it "fails with an error for an order that is still Pending" do
    order.created!
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Order is not awaiting payment"])
    expect(Payment.count).to eq(0)
  end

  it "fails with an error for an order that is already paid" do
    Payment.create!(order:, status: :paid, stripe_id: "ch_123")
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["Order is already paid"])
    expect(Payment.count).to eq(1)
  end

  it "fails with an error while a payment for the order is still pending, as on a double click" do
    service.call
    result = service

    expect(result.call).to be(false)
    expect(result.errors.full_messages).to eq(["A payment is already in progress"])
    expect(Payment.count).to eq(1)
  end

  it "lets the buyer pay again after a declined payment" do
    Payment.create!(order:, status: :failed, failure_message: "Your card was declined.")

    expect(service.call).to have_attributes(status: "pending")
    expect(order.payments.count).to eq(2)
  end

  it "lets the buyer pay again before the copy hears the order is payable again" do
    order.payment_processing!
    Payment.create!(order:, status: :failed, failure_message: "Your card was declined.")

    expect(service.call).to have_attributes(status: "pending")
  end

  it "rejects another user's order before saving anything" do
    expect { service(user_id: next_id).call }.to raise_error(ApiError::NotAuthorized)
    expect(Payment.count).to eq(0)
  end

  it "raises RecordNotFound for an unknown order" do
    expect { service(order_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
