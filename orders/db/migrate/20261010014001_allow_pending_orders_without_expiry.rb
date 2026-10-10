class AllowPendingOrdersWithoutExpiry < ActiveRecord::Migration[8.1]
  # A Pending order (status "created") has no payment deadline; it gets one when its ticket is confirmed
  # and the order is awaiting payment.
  def change
    change_column_null :orders, :expires_at, true
  end
end
