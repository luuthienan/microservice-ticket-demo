Rails.application.routes.draw do
  post "/api/users/signup", to: "users#signup"
  post "/api/users/signin", to: "users#signin"
  post "/api/users/signout", to: "users#signout"
  get "/api/users/currentuser", to: "users#current"
end
