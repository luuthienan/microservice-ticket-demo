class UserAuthentication
  include ActiveModel::Model

  attr_accessor :email, :password

  # Returns the user, or false with errors when the credentials are wrong.
  def call
    user = User.find_by(email:)
    return user if user&.authenticate(password)

    errors.add(:base, "Invalid credentials")
    false
  end
end
