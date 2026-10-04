# Publishes events to Redis Streams: one stream per subject.
class EventPublisher
  def self.redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
  end

  def publish(subject, data)
    self.class.redis.xadd(subject, { data: data.to_json })
  end
end
