class SignupValidator
  include ActiveModel::Model

  attr_reader :email
  attr_accessor :password

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be valid" }
  validates :password, presence: true
  validates :password, length: { in: 4..20 }, allow_blank: true

  # Validate the email the way it will be stored.
  def email=(value)
    @email = User.normalize_value_for(:email, value)
  end
end
