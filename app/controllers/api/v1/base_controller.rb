# v1, versioned from the first commit for the reason Pandatone's is: other
# tools depend on this contract, and the way to change it is to add v2.
#
# Read-only. Patterns are composed in the editor; this is for the tools that
# consume them.
module Api
  module V1
    class BaseController < ActionController::API
      # ActionController::API leaves out everything a browser needs, and
      # content negotiation is on that list. This API answers one route in
      # three formats, so it is put back.
      include ActionController::MimeResponds

      before_action :authenticate_client

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private
        # A token and nothing else — never a session cookie. Stripeclub has no
        # sessions to accept, and accepting one would be how every page on the
        # internet gets to drive this API from a signed-in browser.
        def authenticate_client
          return render_unconfigured if Rails.env.production? && configured_token.blank?
          return if configured_token.blank?

          render_unauthorized unless ActiveSupport::SecurityUtils.secure_compare(
            presented_token.to_s, configured_token
          )
        end

        # Rails reads both spellings of the header, so a client sending the
        # older `Token abc` is not turned away for a reason nobody could guess
        # from a 401.
        def presented_token
          ActionController::HttpAuthentication::Token.token_and_options(request)&.first
        end

        def configured_token
          Rails.application.config.x.api.token
        end

        def render_unauthorized
          render json: { error: "Unauthorized" }, status: :unauthorized
        end

        def render_unconfigured
          render json: { error: "No API token is configured" }, status: :unauthorized
        end

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
