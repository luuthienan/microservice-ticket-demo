class UsersController < ApplicationController
  def signup
    user = User.create!(params.permit(:email, :password))
    sign_in user
    render json: user, status: :created
  end

  def signin
    user = User.find_by(email: params[:email])
    raise ApiError, "Invalid credentials" unless user&.authenticate(params[:password])

    sign_in user
    render json: user
  end

  def signout
    response.delete_cookie("jwt", path: "/")
    render json: {}
  end

  def current
    render json: { currentUser: current_user }
  end

  private

  def sign_in(user)
    expires = 1.day.from_now
    token = JWT.encode({ id: user.id, email: user.email, exp: expires.to_i }, ENV.fetch("JWT_KEY"), "HS256")
    response.set_cookie("jwt", value: token, httponly: true, path: "/", expires:)
  end
end
