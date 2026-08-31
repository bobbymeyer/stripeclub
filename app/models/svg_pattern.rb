# The reference form: a pattern and its colorway as an SVG `<pattern>`.
#
# Everything else Stripeclub exports is a narrowing of this one. It is the
# form that can carry any angle, because a `<pattern>` tile is repeated by the
# renderer and stays seamless however it is transformed — the axis-aligned
# tile and the PNG have to earn that, and can fail to.
#
# There are two shapes of output, and rows are what decides which:
#
#   Without rows, one square tile of stripes, turned to the angle. A single
#   patternTransform, and nothing in the tile that could want a different one.
#
#   With rows, an axis-aligned block of horizontal bands, each filled by a
#   pattern of its own that carries its own turn. That is what makes the four
#   transforms expressible at all — one transform over the whole tile could
#   not let one band lean the other way or run at a different scale — and it
#   is why rows are the vertical seam: the band boundaries supply a vertical
#   period that a stripe at an angle does not have.
class SvgPattern
  include ActionView::Helpers::TagHelper

  # The colorway cannot dress every slot the pattern has.
  NothingToDraw = Class.new(StandardError)

  NAMESPACE = "http://www.w3.org/2000/svg".freeze

  VERTICAL = 90
  HORIZONTAL = 0

  # The repeat in user units, and how much of it the document shows.
  PERIOD = 60
  SIZE = 240

  # Four places of a sixty-unit tile is a ten-thousandth of a pixel at any
  # size anyone will render. Past that the numbers are noise in the file.
  PLACES = 4

  # `dressing` is whatever says what colour each value is: a Colorway, or a
  # ValueScale for a pattern that has not been given a palette yet. The
  # renderer draws structure and asks for fills; which of the two it was
  # handed is not its business.
  # `width` and `height` override the square preview: a standalone tile is
  # exactly one tile across, so that whatever repeats it gets the repeat and
  # not a picture of several.
  #
  # `title` and `desc` are the two things an SVG file says about itself. A
  # tile leaving the application is read by people and by tools that are not
  # this one, and "does this tile?" is the question about it worth answering
  # in the file rather than only on the page it was downloaded from.
  def initialize(dressing, period: PERIOD, size: SIZE, id: nil, width: nil, height: nil, title: nil, desc: nil)
    @dressing = dressing
    @period = period
    @width = width || size
    @height = height || size
    @id = id || dressing.svg_id
    @title, @desc = title, desc
  end

  def to_s
    raise NothingToDraw, "the pattern has slots this colorway's palette cannot fill" if @dressing.invalidated?

    tag.svg(
      safe_join([ *described, tag.defs(safe_join([ definitions, *filters, *frame ])), *surface ]),
      xmlns: NAMESPACE, width: number(@width), height: number(@height),
      viewBox: "0 0 #{number(@width)} #{number(@height)}"
    )
  end

  private
    def described
      [ (tag.title(@title) if @title), (tag.desc(@desc) if @desc) ].compact
    end

    def definitions
      rows.any? ? banded : plain
    end

    # What the tile is painted onto, and — round two — what is done to the
    # paint afterwards. Post-effects: the pattern is drawn clean and then
    # roughened, which is what leaves the composition editable underneath.
    def surface
      [ paint, texture_layer ].compact
    end

    def paint
      return tag.rect(width: "100%", height: "100%", fill: "url(##{@id})") unless wobbly?

      # Painted well outside the frame, then clipped back to it.
      #
      # Outside, because a displacement pulls colour in from beside itself,
      # and at the edge of a rect that is exactly the frame there is nothing
      # beside it to pull — so every drawing would fray into the background
      # rather than into more pattern.
      #
      # Clipped, because the rest of it is not this drawing's to paint. An svg
      # root is meant to clip to its viewport and inline in a page it does
      # not always, so the file says so itself rather than relying on whatever
      # opens it.
      tag.g(
        tag.rect(x: "-50%", y: "-50%", width: "200%", height: "200%",
          fill: "url(##{@id})", filter: "url(##{@id}-wobble)"),
        "clip-path": "url(##{@id}-frame)"
      )
    end

    def frame
      return [] unless wobbly?

      [ tag.clipPath(tag.rect(width: number(@width), height: number(@height)), id: "#{@id}-frame") ]
    end

    def texture_layer
      return nil unless textured?

      tag.rect(width: "100%", height: "100%", filter: "url(##{@id}-texture)",
        opacity: number(imperfection.texture), style: "mix-blend-mode: multiply")
    end

    def filters
      [ (wobble_filter if wobbly?), (texture_filter if textured?) ].compact
    end

    # Turbulence displacing the pattern by its own noise.
    #
    # sRGB rather than the linearRGB a filter uses by default. The noise's
    # channels are read here as numbers — the middle of the range means "leave
    # this pixel where it is" — and converting them to linear light first
    # moves that middle, so the wobble leans one way. A filter that means its
    # numbers rather than its colours says sRGB.
    #
    # stitchTiles is the whole reason this can be put on a repeat. Without it
    # the noise is a field that happens to lie under the pattern and seams
    # wherever the filter's own tile does; with it the noise is generated to
    # meet itself.
    #
    # The displacement is a proportion of the repeat rather than a number of
    # units, so the same pattern drawn twice as large wobbles twice as far. A
    # fixed distance would be a different pattern at every size.
    def wobble_filter
      tag.filter(
        safe_join([
          tag.feTurbulence(type: "fractalNoise", baseFrequency: number(imperfection.wobble_frequency),
            numOctaves: imperfection.wobble_octaves, seed: imperfection.seed,
            stitchTiles: "stitch", result: "wobble-noise"),
          tag.feDisplacementMap(in: "SourceGraphic", in2: "wobble-noise",
            scale: number(imperfection.wobble * @period),
            xChannelSelector: "R", yChannelSelector: "G")
        ]),
        id: "#{@id}-wobble", x: "-20%", y: "-20%", width: "140%", height: "140%",
        "color-interpolation-filters": "sRGB"
      )
    end

    # A noise, desaturated, multiplied over everything. Colour in it would be
    # colour the colorway did not choose, and the linen it is standing in for
    # has none.
    def texture_filter
      tag.filter(
        safe_join([
          tag.feTurbulence(type: "fractalNoise", baseFrequency: number(imperfection.texture_frequency),
            numOctaves: 3, seed: imperfection.seed, stitchTiles: "stitch"),
          tag.feColorMatrix(type: "saturate", values: "0")
        ]),
        id: "#{@id}-texture", "color-interpolation-filters": "sRGB"
      )
    end

    def imperfection
      @dressing.pattern.imperfection
    end

    def wobbly?
      imperfection&.wobbly?
    end

    def textured?
      imperfection&.textured?
    end

    # --- One tile, turned ------------------------------------------------
    def plain
      tag.pattern(
        safe_join(stripes.each_with_index.map { |stripe, index| plain_rect(stripe, index) }),
        id: @id, width: number(@period), height: number(@period), patternUnits: "userSpaceOnUse",
        **turn
      )
    end

    def plain_rect(stripe, index)
      start = edges[index] * @period
      thickness = (edges[index + 1] * @period) - start

      if vertical?
        tag.rect(x: number(start), y: "0", width: number(thickness), height: number(@period), fill: fill_for(stripe))
      else
        tag.rect(x: "0", y: number(start), width: number(@period), height: number(thickness), fill: fill_for(stripe))
      end
    end

    # Measured from the upright, because the upright is what is laid out: at
    # 90° there is nothing to turn.
    #
    # The angle is read anticlockwise from the horizontal *as the page shows
    # it*, so 45° leans the way a forward slash does. SVG's y points down, so
    # anticlockwise on the page is a clockwise rotate — hence 90 − θ and not
    # θ − 90. Rendering it the other way round is not a wrong angle, it is the
    # mirror of the right one, which is the kind of thing that is only ever
    # caught by looking.
    #
    # The axes are laid out directly instead. The geometry is already right,
    # the axis-aligned exports need it in that form regardless, and a
    # rotate(0) over a tile of vertical stripes is something to reason about
    # for no gain at all.
    def turn
      return {} if axis_aligned?

      { patternTransform: rotation }
    end

    def rotation(mirrored: false)
      degrees = VERTICAL - angle

      "rotate(#{number(mirrored ? -degrees : degrees)})"
    end

    # --- A block of bands ------------------------------------------------
    def banded
      safe_join(rows.each_with_index.map { |row, index| row_pattern(row, index) } << block_tile)
    end

    # One row's repeat, at its own scale, turned its own way, and shifted
    # along the normal by its own phase.
    #
    # The phase is the pattern's own x rather than moved rects, because x
    # shifts the whole tiling — so nothing has to be split where the shift
    # runs past the end of the repeat and wraps.
    def row_pattern(row, index)
      repeat = @period * row.width_scale

      tag.pattern(
        safe_join(stripes.each_with_index.map { |stripe, at| row_rect(stripe, at, repeat, row.color_offset) }),
        id: row_id(index), x: number(repeat * row.phase),
        width: number(repeat), height: number(repeat), patternUnits: "userSpaceOnUse",
        patternTransform: rotation(mirrored: row.mirrored?)
      )
    end

    def row_rect(stripe, index, repeat, offset)
      start = edges[index] * repeat
      thickness = (edges[index + 1] * repeat) - start

      tag.rect(x: number(start), y: "0", width: number(thickness), height: number(repeat),
        fill: fill_for(stripe, offset))
    end

    def block_tile
      heights = Proportions.edges(rows.map(&:height))

      tag.pattern(
        safe_join(rows.each_with_index.map { |row, index| band_rect(row, index, heights) }),
        id: @id, width: number(tile_width), height: number(tile_height), patternUnits: "userSpaceOnUse"
      )
    end

    def band_rect(_row, index, heights)
      start = heights[index] * tile_height
      depth = (heights[index + 1] * tile_height) - start

      tag.rect(x: "0", y: number(start), width: number(tile_width), height: number(depth),
        fill: "url(##{row_id(index)})")
    end

    # A whole number of every row's horizontal period, or the rows seam where
    # the tile wraps — and the reference form is not allowed to seam.
    #
    # A stripe at an angle repeats horizontally every P / sin θ, which is the
    # same number Tiling reports for the row-broken mode. At the horizontal
    # there is no such period at all: the pattern does not vary along x, so
    # any width will do and the repeat itself is the tidiest one.
    def tile_width
      span = @period * Row.tile_multiple(rows)

      angle.zero? ? span : span / Math.sin(radians)
    end

    def tile_height
      @period * @dressing.pattern.row_depth
    end

    def row_id(index)
      "#{@id}-row-#{index}"
    end

    # --- Shared ----------------------------------------------------------
    # The widths as drawn, which is not always the widths as stored: variance
    # is geometry, so it moves the rects rather than filtering them.
    def edges
      @edges ||= Proportions.edges(@dressing.pattern.drawn_widths)
    end

    def fill_for(stripe, offset = 0)
      @dressing.color_for(stripe, offset: offset).hex
    end

    def stripes
      @stripes ||= @dressing.pattern.sequence.stripes.to_a
    end

    def rows
      @rows ||= @dressing.pattern.rows.to_a
    end

    def angle
      @dressing.pattern.angle
    end

    def radians
      angle.to_f * Math::PI / 180
    end

    # Everything but the horizontal lays its repeat out along x. The turn puts
    # it where it belongs afterwards.
    def vertical?
      angle != HORIZONTAL
    end

    def axis_aligned?
      [ VERTICAL, HORIZONTAL ].include?(angle)
    end

    def number(value)
      rounded = value.to_f.round(PLACES)

      rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
    end
end
