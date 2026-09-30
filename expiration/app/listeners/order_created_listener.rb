# Schedules a job that fires when the order expires.
class OrderCreatedListener
  def self.subject = "order:created"

  def handle(data)
    ExpireOrderJob.perform_at(Time.iso8601(data["expires_at"]), data["id"])
  end
end
