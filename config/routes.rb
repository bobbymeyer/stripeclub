Stripeclub::Engine.routes.draw do
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
    # they are read together.
    resource :rows, only: %i[ create update destroy ], module: :patterns, as: :row_block

    # One tile, as a file. `.svg` for the geometry and `.png` for the raster,
    # `?colorway=` to have it dressed, `?scale=` to say how many pixels a unit
    # of the tile is worth.
    resource :tile, only: :show, module: :patterns

    # Round two. Made and unmade whole: a pattern either has an imperfection
    # or is clean, and the three effects are set together because they are
    # looked at together.
    resource :imperfection, only: %i[ update destroy ], module: :patterns

    # Dressing a pattern. `new` is the palette picker — the catalogue, fetched
    # once and filtered here — and `create` takes the snapshot.
    resources :colorways, only: %i[ new create destroy ], module: :patterns do
      # Whether the palette has moved since the snapshot was taken. Asked for
      # rather than checked on every page load.
      patch :drift, on: :member
    end
  end

  # The API is versioned from the first commit: other tools depend on this
  # contract, and the way to change it is to add v2, not to edit v1.
  #
  # JSON by default. An explicit .svg or .png still wins, which is how a
  # pattern can be fetched as a picture on the same route.
  #
  # Read-only. Patterns are composed in the editor; this is for the tools that
  # consume them — the way Stripeclub consumes Pandatone.
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # The API describes itself, and the description is not behind the token.
      get "openapi", to: "openapi#show", as: :openapi

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
