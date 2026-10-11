# A payment now exists from the moment it is requested, before the card is charged, so it has a status, holds the
# token until the charge, and has no stripe_id yet. A buyer whose card was declined may try again, so the order is
# unique only among payments that did not fail.
class AddLifecycleToPayments < ActiveRecord::Migration[8.1]
  def change
    # Rows that exist were charged, so they are paid; new rows start pending.
    add_column :payments, :status, :string, null: false, default: "paid"
    change_column_default :payments, :status, from: "paid", to: "pending"
    add_column :payments, :token, :string
    add_column :payments, :failure_message, :string
    change_column_null :payments, :stripe_id, true

    add_index :payments, :order_id, unique: true, where: "status <> 'failed'", name: "index_payments_on_order_id_unfailed"
    remove_index :payments, :order_id, unique: true, name: "index_payments_on_order_id"
    add_index :payments, :order_id
  end
end
