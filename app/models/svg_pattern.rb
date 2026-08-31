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

  # Laid out along an axis, so until patternTransform arrives in step five
  # there is nothing here that can draw an angle between them.
  UnsupportedAngle = Class.new(StandardError)

  NAMESPACE = "http://www.w3.org/2000/svg".freeze

  VERTICAL = 90
  HORIZONTAL = 0

  # The repeat in user units, and how much of it the document shows.
  PERIOD = 60
  SIZE = 240

  # Four places of a sixty-unit tile is a ten-thousandth of a pixel at any
  # size anyone will render. Past that the numbers are noise in the file.
  PLACES = 4

  def initialize(colorway, period: PERIOD, size: SIZE, id: nil)
    @colorway = colorway
    @period = period
    @size = size
    @id = id || "stripeclub-colorway-#{colorway.id}"
  end

  def to_s
    raise NothingToDraw, "the pattern has slots this colorway's palette cannot fill" if @colorway.invalidated?
    raise UnsupportedAngle, "#{angle} is not an axis" unless axis_aligned?

    tag.svg(
      safe_join([ tag.defs(pattern_element), surface ]),
      xmlns: NAMESPACE, width: @size, height: @size, viewBox: "0 0 #{@size} #{@size}"
    )
  end

  private
    def pattern_element
      tag.pattern(
        safe_join(stripes.each_with_index.map { |stripe, index| rect_for(stripe, index) }),
        id: @id, width: number(@period), height: number(@period), patternUnits: "userSpaceOnUse"
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
      @colorway.color_for(stripe.value).hex
    end

    def stripes
      @stripes ||= @colorway.pattern.sequence.stripes.to_a
    end

    def angle
      @colorway.pattern.angle
    end

    def vertical?
      angle == VERTICAL
    end

    def axis_aligned?
      [ VERTICAL, HORIZONTAL ].include?(angle)
    end

    def number(value)
      rounded = value.to_f.round(PLACES)

      rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
    end
end
