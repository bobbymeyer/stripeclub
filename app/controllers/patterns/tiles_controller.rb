# One tile, as a file, for whatever is going to repeat it.
#
# Not the reference form. That is a `<pattern>`, repeated by a renderer that
# knows about the transform on it; this is repeated axis-aligned by something
# that does not, so the tile itself has to close. Which it does — a tile free
# to choose its own size always can.
class Patterns::TilesController < ApplicationController
  def show
    dressing = colorway || ValueScale.new(pattern)

    return head :unprocessable_content if dressing.invalidated?

    respond_to do |format|
      format.svg { render plain: svg(dressing), content_type: "image/svg+xml" }
      format.png { send_data png(dressing).to_blob, type: "image/png", disposition: "inline", filename: filename("png") }
    end
  end

  private
    def pattern
      @pattern ||= Pattern.find(params[:pattern_id])
    end

    def colorway
      pattern.colorways.find_by(id: params[:colorway])
    end

    def svg(dressing)
      params[:form] == "reference" ? reference(dressing) : tile_svg(dressing)
    end

    # The form that carries any angle, because the renderer repeats it and
    # knows about the transform. Several repeats wide, since what it is for is
    # being looked at rather than being tiled by something else.
    def reference(dressing)
      SvgPattern.new(dressing, period: period, size: period * 8, title: pattern.name,
        desc: "The reference form: a pattern element, repeated by the renderer. " \
              "Seamless at any angle, and not a single tile — see the tile export for that.").to_s
    end

    def tile_svg(dressing)
      Tile.new(dressing, period: period).to_svg
    end

    def png(dressing)
      Tile.new(dressing, period: period).to_png(scale: scale)
    end

    def period
      params[:period].presence&.to_i&.clamp(4, 400) || SvgPattern::PERIOD
    end

    # Pixels per unit of the tile. Asked for rather than assumed, because how
    # many pixels a proportion is worth is the only thing a raster needs that
    # the pattern does not say. TilePng brings it down again if the tile it is
    # over would come out bigger than a tile has any business being.
    def scale
      params[:scale].presence&.to_f&.clamp(0.1, 16) || 1.0
    end

    def filename(extension)
      "#{pattern.name.parameterize}-tile.#{extension}"
    end
end
