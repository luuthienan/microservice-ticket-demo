class ConfirmExistingCreatedOrders < ActiveRecord::Migration[8.1]
  # Before orders could be Pending, every created order was payable and had a deadline.
  def up
    execute "UPDATE orders SET status = 'awaiting_payment' WHERE status = 'created'"
  end

  def down
    execute "UPDATE orders SET status = 'created' WHERE status = 'awaiting_payment'"
  end
end
