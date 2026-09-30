class ApiError < StandardError
  attr_reader :status

  def initialize(message, status: 400)
    super(message)
    @status = status
  end

  class NotFound < ApiError
    def initialize = super("Not Found", status: 404)
  end

  class NotAuthorized < ApiError
    def initialize = super("Not authorized", status: 401)
  end
end
