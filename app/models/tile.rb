# One tile of the pattern: how big it has to be to close on itself, and what
# colour is at any point inside it.
#
# Two things the reference form does not need. A `<pattern>` is repeated by
# the renderer, which knows about the transform on it; a tile handed to
# anything else is repeated axis-aligned by something that does not, so the
# geometry has to close on its own. And a PNG has no geometry at all, so the
# pattern has to be available as a function to sample.
#
# That function is the second statement of the same shape the SVG draws as
# rects. It is not duplication for its own sake — a raster needs one and a
# vector needs the other — but the two have to agree, and the tests are where
# they are held to it.
class Tile
  attr_reader :dressing, :period

  def initialize(dressing, period: SvgPattern::PERIOD)
    @dressing = dressing
    @period = period
  end

  def pattern
    dressing.pattern
  end

  # Left free, a tile closes at any angle: W sin θ = P and H cos θ = P is a
  # tile for every θ. The unbroken constraint only bites when the tile's shape
  # is fixed, which is what Snap To Tiling is for — an export gets to choose,
  # so it chooses one that closes.
  # Worked out once and kept as floats. A raster asks for these twice per
  # sample, and reading a decimal column off a record and dividing BigDecimals
  # a few million times over is most of what a slow rasteriser is doing.
  def width
    @width ||= measured_width.to_f
  end

  def height
    @height ||= measured_height.to_f
  end

  def rowed?
    return @rowed unless @rowed.nil?

    @rowed = pattern.rowed?
  end

  def tiling
    Tiling.new(pattern, mode: rowed? ? :row_broken : :unbroken, width: width, height: height)
  end

  def tiles?
    tiling.seamless?
  end

  # The colour at a point, in tile coordinates.
  #
  # Without rows the pattern is one tiling anchored at the origin, so the
  # point is read where it is: a tile that did not close would show it, and
  # that is what makes the closure tests worth running.
  #
  # With rows it is an outer tile of bands, each filled by a pattern anchored
  # to that tile's own origin — so every repetition of the outer tile restarts
  # them, and the point has to be brought back inside it first.
  def color_at(x, y)
    band = band_at(y)

    dressing.color_for(stripes[stripe_index_for(phase_in(band, x, y))], offset: band.offset)
  end

  # Which stripe and which band, rather than which colour.
  #
  # A raster asks per pixel, and the colour a stripe resolves to does not
  # change between them — so a caller that is going to ask a million times can
  # work out the colours once and look them up by these.
  def stripe_index_at(x, y)
    stripe_index_for(phase_at(x, y))
  end

  def row_index_at(y)
    return nil unless rowed?

    band_at(y).index
  end

  def rows
    @rows ||= pattern.rows.to_a
  end

  def stripes
    @stripes ||= pattern.sequence.stripes.to_a
  end

  # Everything about one band that a point inside it does not change: the
  # turn's sine and cosine, the repeat, the shift along it, and how far the
  # colours have moved.
  #
  # A raster asks a million times, and working these out per sample means a
  # million sines of the same angle. Held here rather than in the sampler, so
  # the fast path and `phase_at` are reading the same numbers.
  Band = Data.define(:index, :cos, :sin, :repeat, :shift, :offset, :top, :bottom)

  def bands
    @bands ||= (rowed? ? rows : [ nil ]).each_with_index.map do |row, index|
      turn = radians_of(row&.mirrored? ? -rotation : rotation)
      repeat = (period * (row&.width_scale || 1)).to_f

      Band.new(
        index: index, cos: Math.cos(turn), sin: Math.sin(turn),
        repeat: repeat, shift: repeat * (row&.phase&.to_f || 0),
        offset: row&.color_offset.to_i,
        top: row ? row_edges[index].to_f : 0.0,
        bottom: row ? row_edges[index + 1].to_f : 1.0
      )
    end
  end

  def band_at(y)
    return bands.first unless rowed?

    within = (y % height) / height

    bands.find { |band| within >= band.top && within < band.bottom } || bands.last
  end

  def phase_in(band, x, y)
    local_x, local_y = local(x, y)

    ((((local_x * band.cos) + (local_y * band.sin)) - band.shift) % band.repeat) / band.repeat
  end

  def stripe_index_for(phase)
    index_in(float_edges, phase)
  end

  # How far along the repeat a point is, in 0...1.
  #
  # The pattern as a number rather than as a colour, which is the form the
  # closure of a tile is actually a statement about: a colour lookup has a
  # discontinuity at every stripe edge, so two points a whole tile apart that
  # land exactly on one can come back different for no reason but the last
  # bit of a float.
  #
  # The stripes are laid out along x and then turned, so undoing the turn is
  # what says which one a point is under. The turn is the same 90 − θ the
  # renderer writes, and a mirrored row's is its negative.
  def phase_at(x, y)
    phase_in(band_at(y), x, y)
  end

  private
    def local(x, y)
      rowed? ? [ x % width, y % height ] : [ x, y ]
    end

    def index_in(bounds, at)
      bounds.each_cons(2).find_index { |low, high| at >= low && at < high } || bounds.size - 2
    end

    def measured_width
      return rowed_width if rowed?
      return period if axis_aligned?

      period / Math.sin(radians).abs
    end

    def measured_height
      return period * pattern.row_depth if rowed?
      return period if axis_aligned?

      period / Math.cos(radians).abs
    end

    def rowed_width
      span = period * Row.tile_multiple(rows)

      angle.zero? ? span : span / Math.sin(radians).abs
    end

    # Floats, and this is the hot path's other half. The proportions are
    # BigDecimal because the sum rule is about exact places; comparing a float
    # phase against one converts on every comparison, a million times over.
    def float_edges
      @float_edges ||= Proportions.edges(stripes.map(&:width)).map(&:to_f)
    end

    def row_edges
      @row_edges ||= Proportions.edges(rows.map(&:height))
    end

    def angle
      @angle ||= pattern.angle
    end

    def rotation
      SvgPattern::VERTICAL - angle
    end

    def radians
      radians_of(angle)
    end

    def radians_of(degrees)
      degrees.to_f * Math::PI / 180
    end

    def axis_aligned?
      [ SvgPattern::VERTICAL, SvgPattern::HORIZONTAL ].include?(angle)
    end
end
