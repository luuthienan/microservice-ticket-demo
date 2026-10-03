Rails.application.routes.draw do
  post "/api/v1/payments", to: "payments#create"
end
