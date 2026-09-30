class ExpireOrderJob
  include Sidekiq::Job

  def perform(order_id)
    Events.publish("expiration:complete", { order_id: })
  end
end
