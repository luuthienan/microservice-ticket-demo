Rails.application.routes.draw do
  resources :orders, path: "/api/orders", only: %i[index show create destroy]
end
