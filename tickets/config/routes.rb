Rails.application.routes.draw do
  resources :tickets, path: "/api/tickets", only: %i[index show create update]
end
