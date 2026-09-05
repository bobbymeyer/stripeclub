module Stripeclub
  module Api
    module V1
      class PatternsController < BaseController
        before_action :set_pattern, only: %i[ show tile ]

        # The reads go through the public interface, so what a Ruby caller
        # gets and what an HTTP caller gets are one implementation.
        def index
          render json: Stripeclub.patterns
        end

        def show
          respond_to do |format|
            format.json { render json: Stripeclub.pattern(@pattern.id) }
            format.svg { render plain: reference(ValueScale.new(@pattern)), content_type: "image/svg+xml" }
          end
        end

        # The tile, which is the thing another tool actually repeats. JSON for
        # its measurements, svg and png for the tile itself.
        def tile
          send_tile(ValueScale.new(@pattern), @pattern.name)
        end

        private
          def set_pattern
            @pattern = Pattern.friendly(params[:id])
          end

          # The reference form: a pattern element, repeated by whatever renders
          # it. Seamless at any angle, and the form to reach for unless a single
          # tile is specifically what is wanted.
          def reference(dressing)
            SvgPattern.new(dressing, period: period, size: period * 8, title: @pattern.name,
              desc: "The reference form: a pattern element, repeated by the renderer. " \
                    "Seamless at any angle. See /tile.svg for a single tile.").to_s
          end
      end
    end
  end
end
