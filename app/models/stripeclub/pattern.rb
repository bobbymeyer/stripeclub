# Structure, and only structure: how many slots there are, how the repeat is
# divided between them, which way it runs. A pattern says nothing about
# colour, because whether it reads as high-key, low-key or split is a property
# of the palette a colorway applies to it and not of the pattern at all.
module Stripeclub
  class Pattern < ApplicationRecord
    HALF_TURN = 180

    ValueInUse = Class.new(StandardError)

    # The order these three are declared in is the order they are destroyed in,
    # and it is load-bearing. A value will not go while anything still points at
    # it: a stripe that draws it, or a colorway rule that names it. So the
    # colorways go first, taking their rules, then the sequence, taking its
    # stripes, and only then the values. Reordering these lines makes destroying
    # a pattern raise, which is what the destroy tests are watching.
    has_many :colorways, dependent: :destroy, inverse_of: :pattern
    has_many :rows, -> { order(:position) }, dependent: :destroy, inverse_of: :pattern
    has_one :imperfection, dependent: :destroy, inverse_of: :pattern
    has_one :sequence, dependent: :destroy, inverse_of: :pattern
    has_many :values, -> { order(:position) }, dependent: :destroy, inverse_of: :pattern

    validates :name, presence: true
    validates :slot_count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :angle, presence: true
    validates :row_depth, numericality: { greater_than: 0 }

    validate :row_heights_sum_to_one

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

    # An id or a name. A tool asking for "Awning" should not have to look up a
    # number first, and the name is what a person put on it.
    def self.friendly(key)
      find_by(name: key) || find(key)
    end

    # The widths to draw with: what the sequence holds, or what the pattern's
    # imperfection makes of them. Asked here rather than in each renderer, so
    # the SVG and the raster cannot end up drawing different stripes.
    def drawn_widths
      clean = sequence.stripes.map(&:width)

      imperfection&.widths(clean) || clean
    end

    def rowed?
      rows.any?
    end

    # Break the pattern into bands of equal height. What is done inside each of
    # them is the row's own business afterwards.
    def divide_into_rows!(count)
      heights = Proportions.even(count)

      transaction do
        rows.destroy_all
        count.times { |index| rows.create!(position: index, height: heights[index]) }
      end

      tap { rows.reload }
    end

    private
      # A pattern with no rows is not asked to sum to anything — rows are
      # optional, and their absence is not a block of height zero.
      def row_heights_sum_to_one
        return if rows.empty? || rows.any? { |row| row.height.nil? }

        errors.add(:rows, "must sum to one") unless Proportions.sum_to_one?(rows.map(&:height))
      end

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
end
