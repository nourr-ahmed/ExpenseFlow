Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "me", to: "users#me"

      resources :expenses, except: [:new, :edit] do
        member do
          post :submit
          post :approve
          post :reject
          post :reimburse
          post :reopen
        end
        collection do
          get :review_queue
          get :report
        end
      end

      resources :users, only: [:index, :show, :create, :update]
      resources :teams, only: [:index, :show, :create, :update]
      resources :categories, only: [:index, :create, :update]
    end
  end
end