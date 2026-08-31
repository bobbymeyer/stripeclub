# The repeat unit along the stripe normal: an ordered run of stripes whose
# widths are proportions of it, and therefore sum to one.
class Sequence < ApplicationRecord
  # Places a width is stored to. The sum rule is derived from this rather than
  # given a hand-picked epsilon, so the two cannot drift apart.
  SCALE = 6

  belongs_to :pattern, inverse_of: :sequence
  has_many :stripes, -> { order(:position) }, dependent: :destroy, inverse_of: :sequence

  validate :draws_at_least_one_stripe
  validate :widths_sum_to_one

  # One divided `count` ways, summing to one exactly. Even division of a
  # number that does not divide leaves a remainder, and a remainder has to
  # land somewhere: it lands on the last stripe, because that is the only
  # place it can go without making the first one the odd width.
  def self.even_widths(count)
    each = (BigDecimal(1) / count).floor(SCALE)

    Array.new(count, each).tap { |widths| widths[-1] += 1 - widths.sum }
  end

  def total_width
    stripes.sum { |stripe| stripe.width&.to_d || 0 }
  end

  # Widths scaled back onto one, keeping their proportions to each other. What
  # the editor calls when the designer has been dragging edges around, and
  # what per-stripe jitter will call when it has finished perturbing them.
  def normalize!
    total = total_width
    return self if total.zero?

    transaction do
      scaled = stripes.map { |stripe| (stripe.width.to_d / total).floor(SCALE) }
      scaled[-1] += 1 - scaled.sum

      stripes.each_with_index { |stripe, index| stripe.update!(width: scaled[index]) }
    end

    self
  end

  private
    def draws_at_least_one_stripe
      errors.add(:stripes, "must draw the ground at least") if stripes.empty?
    end

    def widths_sum_to_one
      return if stripes.empty? || stripes.any? { |stripe| stripe.width.nil? }

      errors.add(:stripes, "must sum to one") unless (total_width - 1).abs <= rounding_slack
    end

    # Half a unit in the last stored place, per stripe: the most that rounding
    # to SCALE places can cost and not a step more. A third cannot be written
    # in six places, so three of them come to 0.999999 — a fixed epsilon would
    # have to be loose enough to admit that and would then also admit a
    # sequence that is genuinely short.
    def rounding_slack
      stripes.size * (BigDecimal(1) / 10**SCALE) / 2
    end
end
