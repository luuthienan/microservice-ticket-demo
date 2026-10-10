class RenameCreatedOrderCopiesToAwaitingPayment < ActiveRecord::Migration[8.1]
  # A copy of an order now exists only once the order is awaiting payment (see docs/adr/0005).
  def up
    change_column_default :orders, :status, from: "created", to: "awaiting_payment"
    execute "UPDATE orders SET status = 'awaiting_payment' WHERE status = 'created'"
  end

  def down
    change_column_default :orders, :status, from: "awaiting_payment", to: "created"
    execute "UPDATE orders SET status = 'created' WHERE status = 'awaiting_payment'"
  end
end
