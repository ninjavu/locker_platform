Rails.application.routes.draw do
  root "lockers#index"

  resources :lockers, only: %i[index show] do
    member do
      post :open
      post :close
    end
  end

  get "action_log" => "locker_events#index", as: :action_log

  resource :session, only: :update

  get "up" => "rails/health#show", as: :rails_health_check
end
