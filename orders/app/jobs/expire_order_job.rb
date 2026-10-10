# Cancels an order whose payment time is up. An order that was paid for or cancelled in the meantime is left alone.
class ExpireOrderJob
  include Sidekiq::Job

  def perform(order_id)
    order = Order.find(order_id)
    OrderCancellation.new(order:).call if order.awaiting_payment?
  end
end
