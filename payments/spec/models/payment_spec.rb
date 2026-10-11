require "rails_helper"

RSpec.describe Payment do
  let(:order) { Order.create!(id: next_id, user_id: next_id, price: 20.5, status: :awaiting_payment) }

  it "starts pending, without a Stripe charge" do
    expect(Payment.create!(order:)).to have_attributes(status: "pending", stripe_id: nil, token: nil, failure_message: nil)
  end

  it "allows only one payment per order that has not failed" do
    Payment.create!(order:)

    expect { Payment.create!(order:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "lets a buyer pay again after a failed payment" do
    Payment.create!(order:, status: :failed)

    expect { Payment.create!(order:) }.not_to raise_error
    expect(order.payments.count).to eq(2)
  end
end
