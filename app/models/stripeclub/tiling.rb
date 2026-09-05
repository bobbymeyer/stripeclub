# Whether a pattern closes on itself, for the output mode being asked about.
#
# A status and not a rule. Nothing here refuses to render: an angle that will
# not tile an exported tile is still a perfectly good angle, and the reference
# form draws it seamlessly. What this does is say so, so that Snap To Tiling
# has something to offer and an export has something to warn about.
module Stripeclub
  class Tiling
    include ActionView::Helpers::TextHelper

    MODES = %i[ svg_pattern row_broken unbroken ].freeze

    # Small coprime integers, and this is what "small" means. Past a quarter the
    # tile has to hold too many repeats to be worth exporting.
    LIMIT = 4

    # The angle is stored to three decimal places, so two angles that agree to
    # within half of the last one are the same angle. Derived from the column
    # rather than picked, for the same reason the width sum's slack is.
    PRECISION = 0.0005

    attr_reader :pattern, :mode, :width, :height, :limit

    def initialize(pattern, mode: :unbroken, width: 1.0, height: 1.0, limit: LIMIT)
      raise ArgumentError, "#{mode.inspect} is not one of #{MODES.inspect}" unless MODES.include?(mode)

      @pattern, @mode = pattern, mode
      @width, @height, @limit = width.to_f, height.to_f, limit
    end

    def status
      case mode
      when :svg_pattern then :seamless
      when :row_broken then row_broken_status
      when :unbroken then unbroken_status
      end
    end

    def seamless?
      status != :does_not_tile
    end

    def angle
      pattern.angle.to_f
    end

    # tan θ measured against the tile rather than against the page: the same
    # angle closes on a square and not on a tile twice as wide.
    def slope
      return Float::INFINITY if upright?

      Math.tan(radians) * width / height
    end

    # b/a of tan θ = (b·H)/(a·W).
    #
    # Nil when upright, which is the one slope that has no ratio: it is the
    # tree's own upper bound, 1/0, and Ruby has no Rational for it. Vertical
    # stripes tile anyway — see `fits?`.
    def slope_as_ratio
      return nil if upright?

      SternBrocot.nearest(slope.abs, limit)
    end

    # The angle nearest this one that the tile can close on.
    def fitted_angle
      return 90.0 if upright?

      degrees = Math.atan(slope_as_ratio * height / width) * 180 / Math::PI

      leaning_back? ? 180 - degrees : degrees
    end

    # a + b: how many stripe repeats the tile holds, corner to opposite corner.
    # It is what a requested density has to be a multiple of.
    def repeats_across
      return 1 if upright?

      slope_as_ratio.numerator + slope_as_ratio.denominator
    end

    # P / sin θ. What a row-broken tile is wide, given the repeat. Nil at the
    # horizontal, where the pattern does not vary along x and there is no
    # horizontal period to find.
    def horizontal_period(period)
      return nil if flat?

      period / Math.sin(radians)
    end

    def reason
      case status
      when :seamless then seamless_reason
      when :seamless_with_rows
        "#{pluralize(pattern.rows.size, "row")} carry the vertical seam, so any angle closes. " \
          "The tile is the repeat over sin #{in_degrees(angle)}, " \
          "times #{Row.tile_multiple(pattern.rows)} for the widest row."
      when :does_not_tile
        "#{in_degrees(angle)} does not close on a tile this shape. " \
          "The nearest that does is #{in_degrees(fitted_angle)}, a slope of " \
          "#{slope_as_ratio.numerator}/#{slope_as_ratio.denominator}."
      end
    end

    # Three places is the column's precision, and a whole number of degrees
    # should read as one rather than as itself with a nought after it.
    def in_degrees(value)
      rounded = value.round(3)

      "#{rounded == rounded.to_i ? rounded.to_i : rounded}°"
    end

    private
      # Rows are the vertical seam, so a pattern that has none has nothing to
      # break the tile on — and a row-broken tile of a pattern without rows is
      # just an unbroken tile, held to the same constraint.
      def row_broken_status
        pattern.rowed? ? :seamless_with_rows : unbroken_status
      end

      def unbroken_status
        fits? ? :seamless : :does_not_tile
      end

      def radians
        angle * Math::PI / 180
      end

      def upright?
        angle == 90
      end

      def flat?
        angle.zero?
      end

      def leaning_back?
        angle > 90
      end

      # Both axes close on any rectangle, because the pattern does not vary
      # along one of them: the tile is one repeat wide, or one repeat tall, and
      # nothing has to line up diagonally at all.
      def fits?
        return true if upright? || flat?

        (angle - fitted_angle).abs <= PRECISION
      end

      def seamless_reason
        case mode
        when :svg_pattern
          "A transformed pattern turns its tiles and the lattice they sit on together, so it always closes."
        when :unbroken
          if upright? || flat?
            "The pattern does not vary along one axis, so the tile closes whatever its shape."
          else
            "tan #{in_degrees(angle)} is #{slope_as_ratio.numerator}/#{slope_as_ratio.denominator} " \
              "against this tile, which holds #{repeats_across} repeats across."
          end
        end
      end
  end
end
