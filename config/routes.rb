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

    # The row block is one thing: dividing replaces whatever was there,
    # removing takes all of it, and the transforms are saved together because
    # they are read together. A form per row would also have to sit inside the
    # table that lays them out, and a form is not allowed to be a child of a
    # tbody — the browser lifts it out and the table comes apart.
    resource :rows, only: %i[ create update destroy ], module: :patterns, as: :row_block

    # One tile, as a file. `.svg` for the geometry and `.png` for the raster,
    # `?colorway=` to have it dressed, `?scale=` to say how many pixels a unit
    # of the tile is worth.
    resource :tile, only: :show, module: :patterns

    # Round two. Made and unmade whole: a pattern either has an imperfection
    # or is clean, and the three effects are set together because they are
    # looked at together.
    resource :imperfection, only: %i[ update destroy ], module: :patterns

    # Dressing a pattern. `new` is the palette picker — Pandatone's catalogue,
    # fetched once and filtered here — and `create` takes the snapshot.
    resources :colorways, only: %i[ new create destroy ], module: :patterns do
      # Whether Pandatone's palette has moved since the snapshot was taken.
      # Asked for rather than checked on every page load: it is a round trip,
      # and drift is news rather than weather.
      patch :drift, on: :member
    end
  end

  # The API is versioned from the first commit: other tools depend on this
  # contract, and the way to change it is to add v2, not to edit v1.
  #
  # JSON by default, so a request that names no format gets the one this API
  # published itself as. An explicit .svg or .png still wins, which is how a
  # pattern can be fetched as a picture on the same route.
  #
  # Read-only. Patterns are composed in the editor; this is for the tools that
  # consume them — the way Stripeclub consumes Pandatone.
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :patterns, only: %i[ index show ] do
        get :tile, on: :member
      end

      resources :colorways, only: %i[ index show ] do
        get :tile, on: :member
      end
    end
  end

  root "patterns#index"
end
