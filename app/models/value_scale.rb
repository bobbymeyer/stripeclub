# A pattern shown in value alone: no palette, the slots drawn as the grays
# their ranks are.
#
# Composition happens before a palette is chosen, so the thing being composed
# has to be visible without one — and a pattern is structure, so drawing it in
# value is not a placeholder for the real thing, it is the pattern as it
# actually is.
#
# The range is its-swiss's own ladder, paper at 98% lightness down to ink at
# 18%, which is why an undressed pattern sits in the interface rather than on
# top of it.
#
# It answers everything a colorway answers, so the renderer never learns which
# of the two it was handed.
class ValueScale
  PAPER = 0.98
  INK = 0.18

  attr_reader :pattern

  def initialize(pattern)
    @pattern = pattern
  end

  def svg_id
    "stripeclub-pattern-#{pattern.id}"
  end

  # There is no palette here to be outgrown: adding a slot adds a step to the
  # ladder and the ladder restates itself.
  def invalidated?
    false
  end

  def color_for(value)
    Pandatone::Color.new(
      id: value.position, name: "Value #{value.position}", hex: Luminance.gray(lightness_for(value.position))
    )
  end

  def colors
    pattern.values.map { |value| color_for(value) }
  end

  private
    def lightness_for(position)
      return PAPER if pattern.slot_count <= 1

      PAPER - ((PAPER - INK) * position / (pattern.slot_count - 1.0))
    end
end
