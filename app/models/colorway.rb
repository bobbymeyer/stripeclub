# A pattern wearing a palette. The pattern is the structure and carries no
# colour; this is where colour is said, and it is said as a rule against a
# palette rather than as a list of hexes — so it survives the structure being
# edited underneath it.
#
# Step three implements one rule, Auto-Value-Match, which is the default.
class Colorway < ApplicationRecord
  belongs_to :pattern
  has_one :snapshot, class_name: "PaletteSnapshot", dependent: :destroy, inverse_of: :colorway

  # Only the values whose rule is not the default. Auto-Value-Match is what a
  # value does when nothing has been said about it, so a row for it would be a
  # row saying nothing — and "+" would have to remember to write one.
  has_many :rules, class_name: "ValueRule", dependent: :destroy, inverse_of: :colorway

  validates :palette_id, presence: true
  validate :palette_serves_the_pattern, on: :create

  # Choosing a palette takes a snapshot of it. The two are one act: there is
  # no moment at which a colorway has a palette id and no colours.
  def palette=(palette)
    self.palette_id = palette.id

    build_snapshot(
      palette_name: palette.name,
      colors: palette.colors.map { |color| snapshot_of(color) },
      taken_at: Time.current
    )
  end

  # Whether the pattern has outgrown the palette.
  #
  # Derived and not stored, which is what lets "−" revive a colorway for
  # nothing. A stored mark would have to be found and cleared by whatever
  # removed the slot, and anything that changed the pattern by another route
  # would leave it lying; asked fresh, it cannot go stale.
  def invalidated?
    snapshot.nil? || snapshot.size < pattern.slot_count
  end

  # The colour of each stripe of the repeat, in order.
  #
  # Per stripe and not per value, because two of the four rules vary along the
  # repeat: Random draws once per stripe, and Increment counts them. A value
  # under either of those has no single colour to report.
  #
  # Empty while invalidated rather than short or padded: a colorway that
  # cannot dress every slot has nothing honest to say about any of them, and
  # the pattern is still there to be looked at underneath.
  def colors
    return [] if invalidated?

    pattern.sequence.stripes.map { |stripe| color_for(stripe) }
  end

  # `offset` is the row's colour offset, passed straight through: how far
  # along the palette this band's colours move.
  def color_for(stripe, offset: 0)
    return nil if invalidated?

    rule_for(stripe.value).color_for(stripe, offset: offset)
  end

  # The rule this value carries, or the default it carries by carrying none.
  # The default is built rather than saved: a colorway that has said nothing
  # about any of its values has no rows at all.
  def rule_for(value)
    stored_rules[value.id] ||= ValueRule.new(colorway: self, value: value, kind: :auto_value_match)
  end

  # Say what a value resolves to. One rule per value, so saying it twice
  # replaces rather than adds.
  def bind(value, kind:, **settings)
    rules.find_or_initialize_by(value: value).tap do |rule|
      rule.update!(kind: kind, settings: settings.stringify_keys)
      @stored_rules = nil
    end
  end

  # What the renderer names the `<pattern>` element, so two previews can sit
  # on one page without one filling itself from the other.
  def svg_id
    "stripeclub-colorway-#{id}"
  end

  def drifted_from?(palette)
    snapshot.present? && snapshot.drifted_from?(palette)
  end

  private
    def stored_rules
      @stored_rules ||= rules.index_by(&:value_id)
    end

    def snapshot_of(color)
      {
        "id" => color.id, "name" => color.name, "hex" => color.hex,
        "rgb" => { "r" => color.red, "g" => color.green, "b" => color.blue }
      }
    end

    def palette_serves_the_pattern
      return if snapshot.nil? || pattern.nil?

      errors.add(:palette, "has fewer colours than the pattern has slots") if snapshot.size < pattern.slot_count
    end
end
