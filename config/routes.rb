Rails.application.routes.draw do
  if Rails.env.development?
    mount ItsSwiss::Engine => "/its-swiss"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :patterns do
    # "+" and "−". A slot is added and removed, never edited and never set to
    # a number: adding one preserves the composition and removing one is
    # refused while a stripe still draws it, and neither of those survives
    # being spelled as an update to a count.
    resource :slot, only: %i[ create destroy ], module: :patterns

    # Snap To Tiling. An update to the pattern's tiling rather than to its
    # angle: what is asked for is "make this close", and which angle does that
    # is the answer, not the request.
    resource :tiling, only: :update, module: :patterns
  end

  root "patterns#index"
end
