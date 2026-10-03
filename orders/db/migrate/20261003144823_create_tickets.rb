# A local copy of the tickets service's data, kept up to date through events.
# Its id is always the source ticket's id, so there is no sequence to draw from.
class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets, id: :bigint, default: nil do |t|
      t.string :title, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :version, null: false, default: 0
      t.timestamps
    end
  end
end
