Rails.application.routes.draw do
  root "dashboard#index"
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  get "financial", to: "financial#index", as: :financial
  resources :cash_checkouts, only: :create
  resources :card_checkouts, only: :create
  post "pix_checkouts", to: "pix_checkouts#create", as: :pix_checkouts
  get "pix/:token", to: "pix_checkouts#show", as: :pix_checkout
  get "pix/:token/status", to: "pix_checkouts#status", as: :status_pix_checkout
  delete "pix/:token", to: "pix_checkouts#destroy"
  post "webhooks/mercado_pago", to: "webhooks/mercado_pago#create", as: :mercado_pago_webhook
  resources :expenses, only: :create do
    patch :mark_paid, on: :member
  end
  resources :fishing_tickets, only: :index do
    patch :redeem, on: :member
  end
  resources :products, only: %i[index update] do
    resources :stock_movements, only: :create
    resources :stock_batches, only: :create
  end
  resource :event_setting, only: :update
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
