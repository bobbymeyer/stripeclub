# v1, versioned from the first commit for the reason Pandatone's is: other
# tools depend on this contract, and the way to change it is to add v2.
#
# Read-only. Patterns are composed in the editor; this is for the tools that
# consume them. Every endpoint inherits from the host's API controller, which
# decides who may call it; what the engine adds is the shape of its own
# refusals and the two parameters a tile takes.
module Stripeclub
  module Api
    module V1
      class BaseController < Stripeclub.api_base_controller_class.constantize
        # ActionController::API leaves out everything a browser needs, and
        # content negotiation is on that list. This API answers one route in
        # three formats, so it is put back.
        include ActionController::MimeResponds

        rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

        private
          def render_not_found
            render json: { error: "Not found" }, status: :not_found
          end

          # How many user units a repeat is, and how many pixels a unit is
          # worth. The only two things a consumer needs that the pattern does
          # not already say.
          def period
            params[:period].presence&.to_i&.clamp(4, 400) || SvgPattern::PERIOD
          end

          def scale
            params[:scale].presence&.to_f&.clamp(0.1, 16) || 1.0
          end

          def send_tile(dressing, name)
            tile = Tile.new(dressing, period: period)

            respond_to do |format|
              format.json { render json: TileSerializer.one(tile) }
              format.svg { render plain: tile.to_svg, content_type: "image/svg+xml" }
              format.png do
                send_data tile.to_png(scale: scale).to_blob,
                  type: "image/png", disposition: "inline", filename: "#{name.parameterize}-tile.png"
              end
            end
          end
      end
    end
  end
end
