Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    resources :challenges, only: %i[show new create edit update]
    post "challenges/:challenge_id/tasks", to: "challenge_tasks#create", as: :challenge_tasks
    delete "challenges/:challenge_id/tasks/:id", to: "challenge_tasks#destroy", as: :challenge_task
    match "publish_challenge/:id", to: "publish_challenges#update", as: :publish_challenge, via: %i[put patch]
  end

  get "join", to: "participants#join", as: :join
  post "join", to: "participants#create"
  get "challenges/:challenge_id/participants/:participant_id/waiting_room",
      to: "waiting_room#new",
      as: :challenge_participant_waiting_room
  get "challenges/:challenge_id/participants/:participant_id/dashboard",
      to: "challange_dashboard#show",
      as: :participant_dashboard
  post "participants/:participant_id/checkins", to: "checkins#create", as: :participant_checkins

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "participants#join"
end
