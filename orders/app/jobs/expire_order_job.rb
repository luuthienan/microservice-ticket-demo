# Cancels an order whose time is up. An order that was paid for or cancelled in the meantime is left alone.
class ExpireOrderJob
  include Sidekiq::Job

  def perform(order_id)
    OrderCancellation.new(order: Order.find(order_id)).call
  end
end
