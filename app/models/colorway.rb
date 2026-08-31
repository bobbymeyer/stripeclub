# A pattern wearing a palette. The pattern is the structure and carries no
# colour; this is where colour is said, and it is said as a rule against a
# palette rather than as a list of hexes — so it survives the structure being
# edited underneath it.
#
# Step three implements one rule, Auto-Value-Match, which is the default.
class Colorway < ApplicationRecord
  belongs_to :pattern
  has_one :snapshot, class_name: "PaletteSnapshot", dependent: :destroy, inverse_of: :colorway

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

  # The colour each value resolves to, in slot order.
  #
  # Empty while invalidated rather than short or padded: a colorway that
  # cannot dress every slot has nothing honest to say about any of them, and
  # the pattern is still there to be looked at underneath.
  def colors
    return [] if invalidated?

    pattern.values.map { |value| color_for(value) }
  end

  # Auto-Value-Match: the palette colour at this value's luminance rank.
  #
  # When the palette has more colours than the pattern has slots the ranks are
  # sampled, and both ends are kept — the ground stays the lightest colour the
  # palette has and the last slot the darkest, because that range is what the
  # palette was chosen for. Sampling from one end would quietly drop it.
  def color_for(value)
    return nil if invalidated?

    snapshot.palette.ranked[rank_for(value.position)]
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
    def rank_for(position)
      return 0 if pattern.slot_count <= 1

      (position * (snapshot.size - 1)).fdiv(pattern.slot_count - 1).round
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
