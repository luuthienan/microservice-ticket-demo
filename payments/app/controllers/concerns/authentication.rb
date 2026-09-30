module Authentication
  private

  # The signed-in user from the "jwt" cookie, or nil.
  def current_user
    return @current_user if defined?(@current_user)

    payload, = JWT.decode(request.cookies["jwt"].to_s, ENV.fetch("JWT_KEY"), true, algorithm: "HS256")
    @current_user = payload.slice("id", "email")
  rescue JWT::DecodeError
    @current_user = nil
  end

  def require_auth
    raise ApiError::NotAuthorized unless current_user
  end
end
