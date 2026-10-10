class AddStatusToTickets < ActiveRecord::Migration[8.1]
  # The Copy of the owning service's ticket status (available, reserved, sold or cancelled).
  def change
    add_column :tickets, :status, :string, default: "available", null: false
  end
end
