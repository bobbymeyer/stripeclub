require "stripeclub/version"
require "stripeclub/engine"
# lib is not autoloaded, so what lives here is required by name.
require "stripeclub/seeds"

# The public interface: what another tool may call, and the only thing it
# may call. Plain arguments in, plain data out — the same hashes the JSON API
# sends — so a caller never holds one of the engine's records, and the same
# signature could be wrapped in HTTP the day this is split to its own deploy.
#
#   Stripeclub.patterns                        # => [ { id:, name:, slot_count:, angle: }, ... ]
#   Stripeclub.pattern("Awning")               # => { id:, name:, ..., sequence:, rows:, colorways: }
#   Stripeclub.colorways                       # => [ { id:, pattern_id:, palette_id:, ... }, ... ]
#   Stripeclub.colorway(12)                    # => { ..., rules:, colors: }
#   Stripeclub.tile("Awning")                  # => { width:, height:, tiles:, note: }
#   Stripeclub.tile_svg("Awning", period: 60)  # => "<svg ...>"
module Stripeclub
  # The host's controllers the engine's inherit from. The host's decide who
  # gets in; the engine never has to know what a user is.
  mattr_accessor :base_controller_class, default: "::ApplicationController"
  mattr_accessor :api_base_controller_class, default: "::ApiController"

  # Where Pandatone is and what to show it at the door, for the HTTP client
  # the engine uses when nobody has said otherwise. Neither is required to
  # boot: Stripeclub composes patterns without a palette in sight, and only
  # choosing one needs Pandatone at all.
  mattr_accessor :pandatone_url, default: ENV["PANDATONE_URL"].presence
  mattr_accessor :pandatone_token, default: ENV["PANDATONE_TOKEN"].presence

  # Where palettes come from: anything that answers `call` with an array of
  # palettes in Pandatone's wire format — id, name, tags, and colors each
  # with id, name, hex and rgb. The default fetches them over HTTP from the
  # Pandatone above. A host that has Pandatone in the same process hands
  # over a lambda that asks it directly, and Stripeclub never learns the
  # difference — which is the point: it knows Pandatone by its wire format
  # and by nothing else.
  mattr_accessor :palette_source, default: -> { Stripeclub::Pandatone::Client.configured.palettes_json }

  class << self
    def patterns
      PatternSerializer.many(Pattern.order(:name))
    end

    # One pattern with its structure, by id or by name, or nil.
    def pattern(key)
      pattern = Pattern.friendly(key)
      PatternSerializer.one(pattern) if pattern
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def colorways
      ColorwaySerializer.many(Colorway.order(:id))
    end

    def colorway(id)
      colorway = Colorway.find_by(id: id)
      ColorwaySerializer.one(colorway) if colorway
    end

    # The tile's measurements: how big one closing tile of the pattern is and
    # whether it closes at all. Dressed in a colorway when one is named.
    def tile(key, colorway: nil, period: SvgPattern::PERIOD)
      dressing = dressing_for(key, colorway)
      TileSerializer.one(Tile.new(dressing, period: period)) if dressing
    end

    # The tile itself, as an SVG document.
    def tile_svg(key, colorway: nil, period: SvgPattern::PERIOD)
      dressing = dressing_for(key, colorway)
      Tile.new(dressing, period: period).to_svg if dressing
    end

    # The API's description of itself, as a Hash ready to serve as JSON.
    def openapi
      @openapi ||= YAML.safe_load_file(Engine.root.join("config/openapi.yml"))
    end

    private
      def dressing_for(key, colorway_id)
        pattern = Pattern.friendly(key)
        return ValueScale.new(pattern) if colorway_id.nil?

        colorway = pattern.colorways.find_by(id: colorway_id)
        colorway unless colorway.nil? || colorway.invalidated?
      rescue ActiveRecord::RecordNotFound
        nil
      end
  end
end
