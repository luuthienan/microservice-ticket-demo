# A local copy of the tickets service's data, kept up to date through events.
class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets, id: :uuid do |t|
      t.string :title, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :version, null: false, default: 0
      t.timestamps
    end
  end
end
