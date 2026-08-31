# The wire format for a colorway. Key order here is the key order downstream
# tools see, and the contract test pins it, so treat this file as the
# interface.
module ColorwaySerializer
  module_function

  def summary(colorway)
    {
      id: colorway.id, pattern_id: colorway.pattern_id, palette_id: colorway.palette_id,
      palette_name: colorway.snapshot&.palette_name, invalidated: colorway.invalidated?
    }
  end

  def one(colorway)
    summary(colorway).merge(
      taken_at: colorway.snapshot&.taken_at&.iso8601,
      rules: colorway.pattern.values.map { |value| rule(colorway.rule_for(value)) },
      colors: colorway.colors.map(&:hex)
    )
  end

  def many(colorways)
    colorways.map { |colorway| summary(colorway) }
  end

  # The rule, not the colour it happened to produce. A colorway is a rule over
  # a palette, and a consumer that wants to know why a stripe is the colour it
  # is needs the rule; `colors` beside it is the answer for one that does not.
  def rule(rule)
    { value: rule.value.position, kind: rule.kind, settings: rule.settings }
  end
end
