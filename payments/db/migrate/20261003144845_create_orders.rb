# A local copy of the orders service's data, kept up to date through events.
# Its id is always the source order's id, so there is no sequence to draw from.
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :bigint, default: nil do |t|
      t.bigint :user_id, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "created"
      t.integer :version, null: false, default: 0
      t.timestamps
    end
  end
end
