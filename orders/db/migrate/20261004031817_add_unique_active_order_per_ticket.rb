class AddUniqueActiveOrderPerTicket < ActiveRecord::Migration[8.1]
  # A ticket has at most one order that is not cancelled; cancelled orders may pile up.
  def change
    add_index :orders, :ticket_id, unique: true, where: "status <> 'cancelled'", name: "index_orders_on_ticket_id_active"
  end
end
