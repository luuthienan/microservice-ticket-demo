class ExpireOrderJob
  include Sidekiq::Job

  def perform(order_id)
    EventPublisher.new.publish("expiration:complete", { order_id: })
  end
end
