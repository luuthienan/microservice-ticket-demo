class UserRegistration
  include ActiveModel::Model

  attr_accessor :email, :password

  # Returns the new user, or false with errors when the email is taken.
  def call
    return email_in_use if User.exists?(email:)

    User.create!(email:, password:)
  rescue ActiveRecord::RecordNotUnique
    email_in_use
  end

  private

  def email_in_use
    errors.add(:email, "in use")
    false
  end
end
