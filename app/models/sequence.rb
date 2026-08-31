# The repeat unit along the stripe normal: an ordered run of stripes whose
# widths are proportions of it, and therefore sum to one.
class Sequence < ApplicationRecord
  belongs_to :pattern, inverse_of: :sequence
  has_many :stripes, -> { order(:position) }, dependent: :destroy, inverse_of: :sequence

  validate :draws_at_least_one_stripe
  validate :widths_sum_to_one

  def self.even_widths(count)
    Proportions.even(count)
  end

  def total_width
    Proportions.total(stripes.map(&:width))
  end

  # Widths scaled back onto one, keeping their proportions to each other. What
  # the editor calls when the designer has been dragging edges around, and
  # what per-stripe jitter will call when it has finished perturbing them.
  def normalize!
    scaled = Proportions.normalized(stripes.map(&:width))

    transaction do
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

      errors.add(:stripes, "must sum to one") unless Proportions.sum_to_one?(stripes.map(&:width))
    end
end
