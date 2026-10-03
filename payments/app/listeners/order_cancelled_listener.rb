class OrderCancelledListener
  def self.subject = "order:cancelled"

  def handle(data)
    OrderCopyCancellation.new(data.slice("id", "version")).call
  end
end
