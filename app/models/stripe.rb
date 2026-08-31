# A width and the value it draws. There are no blank stripes: the ground is
# slot 0 and takes a stripe of its own, so every part of the repeat is
# something a colorway can speak about.
class Stripe < ApplicationRecord
  belongs_to :sequence, inverse_of: :stripes
  belongs_to :value, inverse_of: :stripes

  # A proportion of the repeat, so never more than all of it, and never none
  # of it — a stripe of no width is a stripe that is not there, and the repeat
  # reads more plainly with it removed than with it kept at zero.
  validates :width, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :draws_a_value_of_its_own_pattern

  private
    def draws_a_value_of_its_own_pattern
      return if value.nil? || sequence.nil?

      errors.add(:value, "belongs to another pattern") unless value.pattern_id == sequence.pattern_id
    end
end
