Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :tickets, only: %i[index show create update] do
        get :mine, on: :collection
      end
    end
  end
end
