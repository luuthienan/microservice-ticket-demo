# Consumes events from Redis Streams: one stream per subject, one consumer group per service.
# Each listener class responds to `.subject` and `#handle(data)`. An event is acked only when
# its handler succeeds; otherwise it is redelivered once it has been pending for ACK_WAIT_MS.
class EventConsumer
  ACK_WAIT_MS = 5_000

  def self.redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL"))
  end

  def initialize(group, listeners)
    @group = group
    @handlers = listeners.index_by(&:subject)
    @consumer = "#{group}-#{Process.pid}"
  end

  # Runs forever.
  def listen
    create_groups
    loop { poll }
  end

  # One pass: redeliver stale entries, then read fresh ones.
  def poll
    @handlers.each do |subject, listener|
      stale = redis.xautoclaim(subject, @group, @consumer, ACK_WAIT_MS, "0-0", count: 10)
      deliver(listener, subject, stale["entries"])
    end

    fresh = redis.xreadgroup(@group, @consumer, @handlers.keys, @handlers.keys.map { ">" }, count: 10, block: 1000)
    fresh.each { |subject, entries| deliver(@handlers[subject], subject, entries) }
  end

  private

  def redis
    self.class.redis
  end

  def create_groups
    @handlers.each_key { |subject| create_group(subject) }
  end

  def create_group(subject)
    redis.xgroup(:create, subject, @group, "0", mkstream: true)
  rescue Redis::CommandError => e
    raise unless e.message.start_with?("BUSYGROUP")
  end

  def deliver(listener, subject, entries)
    entries.each do |id, fields|
      listener.new.handle(JSON.parse(fields["data"]))
      redis.xack(subject, @group, id)
    rescue => e
      warn "#{subject} #{id} failed, will retry: #{e.class}: #{e.message}"
    end
  end
end
