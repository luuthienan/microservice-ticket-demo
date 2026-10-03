class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.bigint :user_id, null: false
      t.string :status, null: false, default: "created"
      t.datetime :expires_at, null: false
      t.references :ticket, null: false, foreign_key: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
  end
end
