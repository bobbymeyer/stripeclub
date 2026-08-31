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
  def initialize(dressing, period: PERIOD, size: SIZE, id: nil)
    @dressing = dressing
    @period = period
    @size = size
    @id = id || dressing.svg_id
  end

  def to_s
    raise NothingToDraw, "the pattern has slots this colorway's palette cannot fill" if @dressing.invalidated?

    tag.svg(
      safe_join([ tag.defs(definitions), surface ]),
      xmlns: NAMESPACE, width: @size, height: @size, viewBox: "0 0 #{@size} #{@size}"
    )
  end

  private
    def definitions
      rows.any? ? banded : plain
    end

    def surface
      tag.rect(width: "100%", height: "100%", fill: "url(##{@id})")
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
    def edges
      @edges ||= Proportions.edges(stripes.map(&:width))
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
