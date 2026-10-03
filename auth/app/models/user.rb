class User < ApplicationRecord
  has_secure_password validations: false

  normalizes :email, with: ->(email) { email.strip.downcase }
end
