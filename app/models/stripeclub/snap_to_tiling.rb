# One click from an angle that will not close on an exported tile to the
# nearest one that will.
#
# A mutation, and the only one Stripeclub makes to a composition on the
# strength of a constraint — which is why tiling is a status everywhere else
# and this is a button rather than a validation.
module Stripeclub
  class SnapToTiling
    attr_reader :pattern, :tiling

    def initialize(pattern, width: 1.0, height: 1.0, limit: Tiling::LIMIT, repeats: nil)
      @pattern = pattern
      @tiling = Tiling.new(pattern, mode: :unbroken, width: width, height: height, limit: limit)
      @requested = repeats
    end

    def angle
      tiling.fitted_angle
    end

    def slope_as_ratio
      tiling.slope_as_ratio
    end

    def repeats_across
      tiling.repeats_across
    end

    def changed?
      !tiling.seamless?
    end

    # The density the tile can actually close on: the nearest multiple of the
    # repeats it holds, and never nothing — a tile of no repeats is not a
    # coarser pattern, it is a blank square.
    def repeats
      return nil if @requested.nil?

      [ (@requested.to_f / repeats_across).round * repeats_across, repeats_across ].max
    end

    def apply!
      pattern.update!(angle: angle) if changed?

      pattern
    end
  end
end
