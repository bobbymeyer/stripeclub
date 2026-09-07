# What one value of a colorway resolves to.
#
# A rule and not an assignment, which is the difference the whole design turns
# on: a colorway that stored hexes would be wrong the moment the structure
# under it changed, and a rule is still right.
#
# Two of the four kinds are every consumer's, and Pandatone's dresser has them:
# Auto-Value-Match reads the value's rank, Assigned Slot a position in the
# palette. The other two are a stripe pattern's own, because they vary along
# the repeat: Random draws once per stripe and Increment counts them.
module Stripeclub
  class ValueRule < ApplicationRecord
    include Pandatone::Dresser::Rule

    KINDS = (Pandatone::Dresser::Rule::KINDS + %w[ random increment ]).freeze

    def self.kinds = KINDS

    kind_predicates "random", "increment"

    belongs_to :value

    store_accessor :settings, :subset, :seed, :start, :step

    before_validation :seed_itself, if: :random?

    validate :repeat_settings_fit_the_palette

    # `offset` is a row's colour offset, and it moves the answer along by that
    # many colours whichever rule produced it.
    #
    # For a random draw it moves within the subset rather than within the
    # palette. A subset is a promise about which colours can appear, and an
    # offset that walked out of it would break the promise a row at a time.
    def color_for(stripe, offset: 0)
      case kind
      when "auto_value_match" then ranked_along(offset)
      when "assigned_slot" then assigned_color(offset)
      when "random" then at(subset[(draws[stripe.position % draws.size] + offset) % subset.size])
      when "increment" then at(start + (stripe.position * step) + offset)
      end
    end

    # How many stripes before an increment comes back to where it started. The
    # palette over what it shares with the step: stepping two through four
    # colours only ever touches two of them.
    def cycle_length
      return nil unless increment?

      size / size.gcd(step.abs)
    end

    # An increment only closes on itself when the stripes are a whole number of
    # cycles. Anything else lands mid-cycle at the seam and the repeat shows it.
    def closes?(stripe_count)
      return true unless increment?

      (stripe_count % cycle_length).zero?
    end

    private
      # Auto-Value-Match by the dresser's rank, then the row's offset moves the
      # answer along the ranked palette rather than its stored order.
      def ranked_along(offset)
        return color_at_rank(value.position, of: colorway.slot_count) if offset.zero?

        ranked = colorway.snapshot.palette.ranked
        ranked[(ranked.index(color_at_rank(value.position, of: colorway.slot_count)) + offset) % size]
      end

      # One seed, one stream of draws, one tile. Taken in order rather than
      # hashed per stripe, because "seeded per tile" is a statement about the
      # tile as a whole and this is what makes it literally true.
      def draws
        @draws ||= Random.new(seed).then { |rng| Array.new(stripe_count) { rng.rand(subset.size) } }
      end

      def stripe_count
        [ colorway.pattern.sequence.stripes.size, 1 ].max
      end

      # A random rule with no seed would draw differently on every render,
      # which is not a pattern. It picks one rather than refusing, because the
      # seed is not a decision anybody wants to make — only one that has to be
      # kept.
      def seed_itself
        self.seed ||= SecureRandom.random_number(1 << 31)
      end

      def repeat_settings_fit_the_palette
        return if colorway.nil? || colorway.snapshot.nil?

        case kind
        when "increment" then check_increment
        when "random" then check_random
        end
      end

      def check_increment
        check_index(:start, start)

        errors.add(:step, "has to move") unless step.is_a?(Integer) && !step.zero?
      end

      def check_random
        errors.add(:seed, "has to be kept, or the tile draws differently every time") unless seed.is_a?(Integer)

        return errors.add(:subset, "has to be at least one colour") unless subset.is_a?(Array) && subset.any?

        subset.each { |index| check_index(:subset, index) }
      end
  end
end
