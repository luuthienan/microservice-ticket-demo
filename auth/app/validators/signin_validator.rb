class SigninValidator
  include ActiveModel::Model

  attr_accessor :email, :password

  validates :email, :password, presence: true
end
