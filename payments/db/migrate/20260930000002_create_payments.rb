class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :order, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.string :stripe_id, null: false
      t.timestamps
    end
  end
end
