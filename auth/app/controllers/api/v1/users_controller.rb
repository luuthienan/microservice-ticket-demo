class Api::V1::UsersController < ApplicationController
  def signup
    validator = SignupValidator.new(params.permit(:email, :password))
    return render_validation_errors(validator) unless validator.valid?

    service = UserRegistration.new(email: validator.email, password: validator.password)
    user = service.call
    return render_validation_errors(service) unless user

    sign_in user
    render json: user, status: :created
  end

  def signin
    validator = SigninValidator.new(params.permit(:email, :password))
    return render_validation_errors(validator) unless validator.valid?

    service = UserAuthentication.new(email: validator.email, password: validator.password)
    user = service.call
    return render_validation_errors(service) unless user

    sign_in user
    render json: user
  end

  def signout
    response.delete_cookie("jwt", path: "/")
    render json: {}
  end

  def current
    render json: { current_user: current_user }
  end

  private

  def sign_in(user)
    issuance = AuthTokenIssuance.new(user:)
    response.set_cookie("jwt", value: issuance.call, httponly: true, path: "/", expires: issuance.expires_at)
  end
end
