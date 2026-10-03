Rails.application.routes.draw do
  resources :orders, path: "/api/v1/orders", only: %i[index show create destroy]
end
