class OrderCreatedListener
  def self.subject = "order:created"

  def handle(data)
    OrderCopyCreation.new(
      id: data["id"], user_id: data["user_id"], status: data["status"],
      price: data["ticket"]["price"], version: data["version"]
    ).call
  end
end
