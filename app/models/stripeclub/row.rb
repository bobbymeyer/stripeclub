# A horizontal band of the pattern, and what is done to the repeat inside it.
#
# Rows are the vertical seam. A stripe at an angle has no vertical period of
# its own that an axis-aligned tile can use, and the band boundaries supply
# one — which is why a row-broken tile takes any angle where an unbroken one
# takes only the angles that fit it.
module Stripeclub
  class Row < ApplicationRecord
    belongs_to :pattern, inverse_of: :rows

    validates :position, presence: true,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 },
      uniqueness: { scope: :pattern_id }

    validates :height, numericality: { greater_than: 0, less_than_or_equal_to: 1 }

    # A whole period of shift is no shift, so the range stops short of one.
    validates :phase, numericality: { greater_than_or_equal_to: 0, less_than: 1 }

    validates :width_numerator, :width_denominator,
      numericality: { only_integer: true, greater_than: 0 }

    def width_scale
      Rational(width_numerator, width_denominator)
    end

    # How many repeats wide the tile has to be for every row to divide it a
    # whole number of times. The least common multiple of the rows' scales, and
    # for fractions that is the lcm of the numerators over the gcd of the
    # denominators.
    #
    # Without it a row whose repeat does not divide the tile seams every time
    # the tile wraps — which the reference form is not allowed to do.
    def self.tile_multiple(rows)
      return Rational(1, 1) if rows.empty?

      scales = rows.map(&:width_scale)

      Rational(
        scales.map(&:numerator).reduce(1, :lcm),
        scales.map(&:denominator).reduce { |a, b| a.gcd(b) }
      )
    end
  end
end
