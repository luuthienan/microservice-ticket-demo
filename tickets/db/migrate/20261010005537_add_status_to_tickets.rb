class AddStatusToTickets < ActiveRecord::Migration[8.1]
  # status is the source of truth for where a ticket stands; order_id names the order that holds or bought it.
  def change
    add_column :tickets, :status, :string, default: "available", null: false
    add_check_constraint :tickets, "status IN ('available', 'reserved', 'sold', 'cancelled')", name: "tickets_status_known"
    add_check_constraint :tickets, "(status IN ('reserved', 'sold')) = (order_id IS NOT NULL)", name: "tickets_order_id_matches_status"
  end
end
