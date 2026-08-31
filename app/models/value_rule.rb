# What one value of a colorway resolves to.
#
# A rule and not an assignment, which is the difference the whole design turns
# on: a colorway that stored hexes would be wrong the moment the structure
# under it changed, and a rule is still right.
#
# Only one of the four reads the value's rank. The other three read a position
# in the palette — which is why a palette reordered in Pandatone counts as
# drift even when every colour in it is unchanged.
class ValueRule < ApplicationRecord
  KINDS = %w[ auto_value_match assigned_slot random increment ].freeze

  belongs_to :colorway
  belongs_to :value

  # Predicates written out rather than taken from `enum`. An enum over these
  # four names generates `increment!`, and Active Record already has one — it
  # is the method Pattern uses to move a slot count. The bang methods are no
  # loss: a rule's kind is set with its settings or not at all, since three of
  # the four are meaningless without them.
  KINDS.each { |name| define_method("#{name}?") { kind == name } }

  validates :kind, inclusion: { in: KINDS }

  store_accessor :settings, :slot, :subset, :seed, :start, :step

  before_validation :seed_itself, if: :random?

  validate :settings_fit_the_palette

  # Whether the value is still doing value work. Auto-Value-Match resolves
  # through the luminance rank, so the value's place in the ladder is what
  # decides its colour; the other three resolve through a position in the
  # palette, and the rank stops mattering. The editor marks the difference.
  def binds_to_rank?
    auto_value_match?
  end

  def color_for(stripe)
    case kind
    when "auto_value_match" then palette.ranked[rank]
    when "assigned_slot" then at(slot)
    when "random" then at(subset[draws[stripe.position % draws.size]])
    when "increment" then at(start + (stripe.position * step))
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
    def palette
      colorway.snapshot.palette
    end

    def size
      colorway.snapshot.size
    end

    def at(index)
      palette.colors[index % size]
    end

    # Auto-Value-Match, and the only place a rank is read. Both ends of the
    # palette are kept when it has more colours than the pattern has slots.
    def rank
      slots = colorway.pattern.slot_count
      return 0 if slots <= 1

      (value.position * (size - 1)).fdiv(slots - 1).round
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

    # A random rule with no seed would draw differently on every render, which
    # is not a pattern. It picks one rather than refusing, because the seed is
    # not a decision anybody wants to make — only one that has to be kept.
    def seed_itself
      self.seed ||= SecureRandom.random_number(1 << 31)
    end

    def settings_fit_the_palette
      return if colorway.nil? || colorway.snapshot.nil?

      case kind
      when "assigned_slot" then check_index(:slot, slot)
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

    # i < p, and not negative. A rule naming a colour the palette does not
    # have is the same mistake as a colorway whose palette cannot fill the
    # pattern, caught in the same place.
    def check_index(attribute, index)
      return if index.is_a?(Integer) && index.between?(0, size - 1)

      errors.add(attribute, "has to name one of the palette's #{size} colours")
    end
end
