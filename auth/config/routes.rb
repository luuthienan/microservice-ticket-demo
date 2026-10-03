Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: [] do
        collection do
          post :signup
          post :signin
          post :signout
          get :currentuser, action: :current
        end
      end
    end
  end
end
