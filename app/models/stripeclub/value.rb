# A rank, 0 to n−1. Slot 0 is the ground.
#
# It stores no luminance. Luminance is computed in Stripeclub from the palette
# a colorway resolves against, and a value that carried one would be answering
# a question about colour that a pattern is not being asked.
module Stripeclub
  class Value < ApplicationRecord
    belongs_to :pattern, inverse_of: :values

    # No dependent option, and that is the guard rather than the absence of one.
    # A value still drawn by a stripe must not disappear and leave the stripe
    # pointing at nothing, and the foreign key on stripes.value_id already
    # refuses it — from the database, where no amount of association loading can
    # talk it round. `dependent: :restrict_with_error` was tried and answers
    # from whatever the association happens to hold in memory, so it refused
    # values whose stripes had already been destroyed in the same transaction.
    #
    # Cascading would be worse than either: deleting a value would take its
    # stripes with it and leave the sequence summing to less than one, silently.
    # Removing a slot means deciding what its stripes draw instead, which is a
    # decision and not a side effect.
    has_many :stripes, inverse_of: :value

    validates :position, presence: true,
      numericality: { only_integer: true, greater_than_or_equal_to: 0 },
      uniqueness: { scope: :pattern_id }
  end
end
