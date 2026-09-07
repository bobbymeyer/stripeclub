require "rails/engine"

# What the engine is built on. Required here rather than left to the host's
# Gemfile: a gem's dependencies are resolved by Bundler and loaded by nobody.
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"
require "its-swiss"
require "pandatone"
require "chunky_png"

module Stripeclub
  # A mountable engine: its own controllers, routes, views, migrations and
  # stylesheets, under one namespace and one table prefix.
  #
  #   mount Stripeclub::Engine, at: "/stripeclub"
  #
  # Two things it takes from the host. The door: every screen inherits from
  # the host's ApplicationController and every API endpoint from the host's
  # API controller (Stripeclub.base_controller_class). The shell: the engine's
  # layout fills its slots and renders the host's layouts/application around
  # them. The palettes it takes from Pandatone, through Pandatone's own
  # dresser: the Pandatone in the same process, or one at PANDATONE_URL.
  class Engine < ::Rails::Engine
    isolate_namespace Stripeclub

    # SVG is not one of the types Rails registers, and a tile is served as one.
    initializer "stripeclub.mime_types" do
      Mime::Type.register "image/svg+xml", :svg unless Mime[:svg]
    end

    # The engine's migrations run with the host's rather than being copied in.
    initializer "stripeclub.migrations" do |app|
      unless app.root.to_s.start_with?(root.to_s)
        config.paths["db/migrate"].expanded.each do |path|
          app.config.paths["db/migrate"] << path
        end
      end
    end
  end
end
