# A local copy of the orders service's data, kept up to date through events.
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "created"
      t.integer :version, null: false, default: 0
      t.timestamps
    end
  end
end
