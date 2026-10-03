Rails.application.routes.draw do
  post "/api/v1/users/signup", to: "users#signup"
  post "/api/v1/users/signin", to: "users#signin"
  post "/api/v1/users/signout", to: "users#signout"
  get "/api/v1/users/currentuser", to: "users#current"
end
