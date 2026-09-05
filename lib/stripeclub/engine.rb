require "rails/engine"

# What the engine is built on. Required here rather than left to the host's
# Gemfile: a gem's dependencies are resolved by Bundler and loaded by nobody.
require "propshaft"
require "importmap-rails"
require "turbo-rails"
require "stimulus-rails"
require "its-swiss"
require "chunky_png"

module Stripeclub
  # A mountable engine: its own controllers, routes, views, migrations and
  # stylesheets, under one namespace and one table prefix.
  #
  #   mount Stripeclub::Engine, at: "/stripeclub"
  #
  # Three things it takes from the host. The door: every screen inherits from
  # the host's ApplicationController and every API endpoint from the host's
  # API controller (Stripeclub.base_controller_class). The shell: the engine's
  # layout fills its slots and renders the host's layouts/application around
  # them. And the palettes: Stripeclub dresses a pattern in a palette it did
  # not make, and where those come from is the host's to say
  # (Stripeclub.palette_source).
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
