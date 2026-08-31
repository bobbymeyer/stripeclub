# Structure, and only structure: how many slots there are, how the repeat is
# divided between them, which way it runs. A pattern says nothing about
# colour, because whether it reads as high-key, low-key or split is a property
# of the palette a colorway applies to it and not of the pattern at all.
class Pattern < ApplicationRecord
  HALF_TURN = 180

  ValueInUse = Class.new(StandardError)

  # The sequence is declared before the values on purpose. Both are destroyed
  # with the pattern, in the order they are declared here, and the foreign key
  # on stripes.value_id will not let a value go while a stripe still draws it
  # — so the stripes have to go first. Reversing these two lines makes
  # destroying a pattern raise, which is what the destroy test is watching.
  has_one :sequence, dependent: :destroy, inverse_of: :pattern
  has_many :values, -> { order(:position) }, dependent: :destroy, inverse_of: :pattern

  validates :name, presence: true
  validates :slot_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :angle, presence: true

  before_validation :fold_angle
  after_create :compose

  # "+". The new slot is a slot and not a stripe: a fourth stripe in a repeat
  # of three changes all three widths to make room for it, and the widths are
  # the composition. What the designer gets is somewhere to point a stripe.
  #
  # Every colorway over this pattern has to rerender, because n has changed
  # and every rank binding was computed against the old one. That is the
  # colorway's business, and it is wired when colorways exist.
  def add_value!
    transaction do
      values.create!(position: slot_count)
      update!(slot_count: slot_count + 1)
    end

    self
  end

  # "−". The mirror of "+", and only for a slot nothing draws: a value with
  # stripes pointing at it cannot go without deciding what those stripes draw
  # instead, which is an edit to the composition rather than to its palette.
  #
  # Every colorway the added slot invalidated comes back on its own, because
  # invalidation is asked rather than stored.
  def remove_value!
    raise ValueInUse, "a pattern keeps its ground" if slot_count <= 1

    values.reload.last.then do |value|
      raise ValueInUse, "slot #{value.position} is still drawn" if value.stripes.exists?

      transaction do
        value.destroy!
        update!(slot_count: slot_count - 1)
      end
    end

    self
  end

  private
    def fold_angle
      self.angle = angle.to_d.modulo(HALF_TURN) if angle
    end

    # A pattern arrives drawable. Its slots divide the repeat evenly and the
    # ground takes the first stripe, which is the plainest structure that is
    # still a pattern — everything else is an edit of it.
    def compose
      slots = Array.new(slot_count) { |rank| values.create!(position: rank) }
      widths = Sequence.even_widths(slot_count)

      build_sequence.tap do |sequence|
        slots.each_with_index do |value, index|
          sequence.stripes.build(value: value, width: widths[index], position: index)
        end

        sequence.save!
      end
    end
end
