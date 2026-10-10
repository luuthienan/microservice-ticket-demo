class RenameCreatedOrderCopiesToAwaitingPayment < ActiveRecord::Migration[8.1]
  # A copy of an order now exists only once the order is awaiting payment (see docs/adr/0005).
  def change
    change_column_default :orders, :status, from: "created", to: "awaiting_payment"
  end
end
