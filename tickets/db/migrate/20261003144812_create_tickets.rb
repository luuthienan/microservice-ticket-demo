class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.bigint :user_id, null: false
      t.bigint :order_id # set while an order holds the ticket
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
  end
end
