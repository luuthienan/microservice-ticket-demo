Rails.application.routes.draw do
  resources :tickets, path: "/api/v1/tickets", only: %i[index show create update]
end
