module Stripeclub
  module Api
    module V1
      class ColorwaysController < BaseController
        before_action :set_colorway, only: %i[ show tile ]

        def index
          render json: Stripeclub.colorways
        end

        def show
          respond_to do |format|
            format.json { render json: Stripeclub.colorway(@colorway.id) }
            format.svg { render_dressed { |dressing| reference(dressing) } }
          end
        end

        def tile
          return render_undressable if @colorway.invalidated?

          send_tile(@colorway, name)
        end

        private
          def set_colorway
            @colorway = Colorway.find(params[:id])
          end

          def name
            "#{@colorway.pattern.name} #{@colorway.snapshot&.palette_name}"
          end

          def render_dressed
            return render_undressable if @colorway.invalidated?

            render plain: yield(@colorway), content_type: "image/svg+xml"
          end

          # The pattern has slots this colorway's palette cannot fill. There is
          # nothing honest to draw, and a tool that got a picture back anyway
          # would be getting a guess.
          def render_undressable
            render json: {
              error: "This colorway cannot dress its pattern",
              slot_count: @colorway.pattern.slot_count, palette_size: @colorway.snapshot&.size
            }, status: :unprocessable_content
          end

          def reference(dressing)
            SvgPattern.new(dressing, period: period, size: period * 8, title: name,
              desc: "The reference form: a pattern element, repeated by the renderer. " \
                    "Seamless at any angle. See /tile.svg for a single tile.").to_s
          end
      end
    end
  end
end
