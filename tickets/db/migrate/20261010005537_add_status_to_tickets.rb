class AddStatusToTickets < ActiveRecord::Migration[8.1]
  # status is the source of truth for where a ticket stands; order_id names the order that holds or bought it.
  def change
    add_column :tickets, :status, :string, default: "available", null: false
  end
end
