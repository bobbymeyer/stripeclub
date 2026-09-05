# Round two: the ways a pattern is allowed to be imperfect.
#
# Post-effects, not geometry. The widths in the sequence stay what someone
# typed and the angle stays what they set; everything here is applied when the
# pattern is drawn. That is the whole design constraint — a composition you
# can still edit after roughening it, rather than one that has been roughened
# into place.
#
# Width variance is the one that looks like an exception and is not: it does
# change the widths, but it computes them from a seed at draw time and leaves
# the stored ones alone. Turn it off and the clean pattern is still there.
module Stripeclub
  class Imperfection < ApplicationRecord
    belongs_to :pattern, inverse_of: :imperfection

    # Past 0.9 a width can be jittered to nothing, and a stripe of no width is a
    # stripe that is not there — which is the one thing the composition promises
    # it will not do behind your back.
    MOST_VARIANCE = 0.9

    validates :wobble, :texture, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :variance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MOST_VARIANCE }
    validates :wobble_frequency, :texture_frequency, numericality: { greater_than: 0, less_than_or_equal_to: 4 }
    validates :wobble_octaves, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }
    validates :seed, presence: true

    before_validation :seed_itself

    def wobbly?
      wobble.positive?
    end

    def varied?
      variance.positive?
    end

    def textured?
      texture.positive?
    end

    def any?
      wobbly? || varied? || textured?
    end

    # Only the geometry can be sampled. A displacement map and a noise multiply
    # are things a renderer does to a picture, and the PNG has no renderer — so
    # a rasterised tile carries the jitter and not the other two.
    def only_geometry?
      varied? && !wobbly? && !textured?
    end

    # The widths as drawn: each one nudged by up to `variance` of itself, then
    # put back onto one.
    #
    # Renormalising is what makes this a rule about proportions rather than a
    # rule about pixels — the sequence still sums to one afterwards, so the
    # repeat is still a repeat and every other piece of arithmetic in the
    # application goes on being true.
    def widths(clean)
      return clean unless varied?

      rng = Random.new(seed)
      nudged = clean.map { |width| width.to_d * (1 + (variance.to_d * ((rng.rand * 2) - 1))) }

      Proportions.normalized(nudged)
    end

    private
      # Imperfection that came out differently on every render would not be a
      # pattern. It picks a seed rather than refusing, because the seed is not a
      # decision anyone wants to make — only one that has to be kept.
      def seed_itself
        self.seed ||= SecureRandom.random_number(1 << 31)
      end
  end
end
