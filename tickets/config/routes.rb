Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :tickets, only: %i[index show create update]
    end
  end
end
