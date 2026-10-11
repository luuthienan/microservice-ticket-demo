require "rails_helper"

RSpec.describe PaymentCharge do
  let(:order) { Order.create!(id: next_id, user_id: next_id, price: 20.5, status: :payment_processing) }
  let!(:payment) { Payment.create!(order:, token: "tok_visa") }

  before { allow(Stripe::Charge).to receive(:create).and_return(double(id: "ch_123")) }

  def declined = Stripe::CardError.new("Your card was declined.", "number", code: "card_declined")

  it "charges the card of the order's price and publishes payment:paid" do
    described_class.new(payment_id: payment.id).call

    expect(Stripe::Charge).to have_received(:create).with(
      { amount: 2050, currency: "usd", source: "tok_visa", description: "Order #{order.id}" },
      { idempotency_key: "payment-#{order.id}-#{payment.id}" }
    )
    expect(payment.reload).to have_attributes(status: "paid", stripe_id: "ch_123")
    expect(event_publisher).to have_received(:publish)
      .with("payment:paid", { id: payment.id, order_id: order.id, stripe_id: "ch_123" })
  end

  it "fails the payment with the reason and publishes payment:failed when the card is declined" do
    allow(Stripe::Charge).to receive(:create).and_raise(declined)

    described_class.new(payment_id: payment.id).call

    expect(payment.reload).to have_attributes(status: "failed", stripe_id: nil, failure_message: "Your card was declined.")
    expect(event_publisher).to have_received(:publish).with("payment:failed", { id: payment.id, order_id: order.id })
  end

  it "fails the payment when Stripe refuses the token, which retrying would not fix" do
    allow(Stripe::Charge).to receive(:create).and_raise(Stripe::InvalidRequestError.new("No such token: 'tok_visa'", "source"))

    described_class.new(payment_id: payment.id).call

    expect(payment.reload).to have_attributes(status: "failed", failure_message: "No such token: 'tok_visa'")
    expect(event_publisher).to have_received(:publish).with("payment:failed", { id: payment.id, order_id: order.id })
  end

  it "raises when Stripe cannot be reached, leaving the payment pending so the event is retried" do
    allow(Stripe::Charge).to receive(:create).and_raise(Stripe::APIConnectionError.new("Connection refused"))

    expect { described_class.new(payment_id: payment.id).call }.to raise_error(Stripe::APIConnectionError)
    expect(payment.reload).to be_pending
    expect(event_publisher).not_to have_received(:publish)
  end

  %i[paid failed].each do |status|
    it "does not charge a payment that is already #{status}, as when the event is replayed" do
      payment.update!(status:)

      described_class.new(payment_id: payment.id).call

      expect(Stripe::Charge).not_to have_received(:create)
      expect(event_publisher).not_to have_received(:publish)
    end
  end

  it "raises RecordNotFound for an unknown payment" do
    expect { described_class.new(payment_id: next_id).call }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
