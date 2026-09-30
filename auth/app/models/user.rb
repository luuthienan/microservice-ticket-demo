class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be valid" }
  validates :email, uniqueness: { message: "in use" }
  validates :password, length: { in: 4..20 }, allow_nil: true

  def as_json(*) = super(only: %i[id email])
end
