class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets, id: :uuid do |t|
      t.string :title, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.uuid :user_id, null: false
      t.uuid :order_id # set while an order holds the ticket
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
  end
end
