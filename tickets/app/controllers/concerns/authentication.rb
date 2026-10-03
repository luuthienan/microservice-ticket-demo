module Authentication
  private

  # The signed-in user from the "jwt" cookie, or nil.
  def current_user
    return @current_user if defined?(@current_user)

    payload, = JWT.decode(request.cookies["jwt"].to_s, ENV.fetch("JWT_KEY"), true, algorithm: "HS256")
    # Only integer ids are valid; a stale uuid-era token must not be cast to a bigint.
    @current_user = payload["id"].is_a?(Integer) ? payload.slice("id", "email") : nil
  rescue JWT::DecodeError
    @current_user = nil
  end

  def require_auth
    raise ApiError::NotAuthorized unless current_user
  end
end
