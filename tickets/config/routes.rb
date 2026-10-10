Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :tickets, only: %i[index show create update] do
        get :mine, on: :collection
        post :cancel, on: :member
      end
    end
  end
end
