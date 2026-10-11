class AddPaymentIdToOrders < ActiveRecord::Migration[8.1]
  # The payment (owned by the payments service) this order was last claimed for. Payment events name the payment they
  # are about, so a replayed or late one for an earlier attempt can be told from the current one.
  def change
    add_column :orders, :payment_id, :bigint
  end
end
