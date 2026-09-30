Rails.application.routes.draw do
  post "/api/payments", to: "payments#create"
end
