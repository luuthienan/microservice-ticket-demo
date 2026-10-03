# Issues the signed JWT carried in the session cookie.
class AuthTokenIssuance
  include ActiveModel::Model

  EXPIRES_IN = 1.day

  attr_accessor :user

  def call
    JWT.encode({ id: user.id, email: user.email, exp: expires_at.to_i }, ENV.fetch("JWT_KEY"), "HS256")
  end

  def expires_at
    @expires_at ||= EXPIRES_IN.from_now
  end
end
