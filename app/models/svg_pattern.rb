# The reference form: a pattern and its colorway as an SVG `<pattern>`.
#
# Everything else Stripeclub exports is a narrowing of this one. It is the
# form that can carry any angle, because a `<pattern>` tile is repeated by the
# renderer and stays seamless however it is transformed — the axis-aligned
# tile and the PNG have to earn that, and can fail to.
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
      safe_join([ tag.defs(pattern_element), surface ]),
      xmlns: NAMESPACE, width: @size, height: @size, viewBox: "0 0 #{@size} #{@size}"
    )
  end

  private
    def pattern_element
      tag.pattern(
        safe_join(stripes.each_with_index.map { |stripe, index| rect_for(stripe, index) }),
        id: @id, width: number(@period), height: number(@period), patternUnits: "userSpaceOnUse",
        **turn
      )
    end

    def surface
      tag.rect(width: "100%", height: "100%", fill: "url(##{@id})")
    end

    def rect_for(stripe, index)
      start = edges[index] * @period
      thickness = (edges[index + 1] * @period) - start

      if vertical?
        tag.rect(x: number(start), y: "0", width: number(thickness), height: number(@period), fill: fill_for(stripe))
      else
        tag.rect(x: "0", y: number(start), width: number(@period), height: number(thickness), fill: fill_for(stripe))
      end
    end

    # Any angle, by turning the tile rather than by laying the stripes out
    # along it. patternTransform turns the tile and the lattice it repeats on
    # together, so the tiles go on meeting however far round it goes — which
    # is the whole reason this form never has to warn about an angle.
    #
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

      { patternTransform: "rotate(#{number(VERTICAL - angle)})" }
    end

    # The edges of the repeat, as proportions, with the last one placed at the
    # period rather than accumulated to it.
    #
    # Widths are stored to six places and a sequence of thirds sums to
    # 0.999999, which is as close to one as six places allow. Multiplied out
    # that is a hairline of whatever is behind the pattern showing through
    # every repeat, which is the one thing a repeat may not do.
    def edges
      @edges ||= begin
        running = BigDecimal(0)
        bounds = stripes.map { |stripe| running.tap { running += stripe.width } }

        bounds << BigDecimal(1)
      end
    end

    def fill_for(stripe)
      @dressing.color_for(stripe.value).hex
    end

    def stripes
      @stripes ||= @dressing.pattern.sequence.stripes.to_a
    end

    def angle
      @dressing.pattern.angle
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
