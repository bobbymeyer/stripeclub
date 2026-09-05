# The wire format for a pattern. Key order here is the key order downstream
# tools see, and the contract test pins it, so treat this file as the
# interface.
module Stripeclub
  module PatternSerializer
    module_function

    # Collections and embedded references carry the summary; only a pattern
    # asked for by itself carries its structure.
    def summary(pattern)
      { id: pattern.id, name: pattern.name, slot_count: pattern.slot_count, angle: pattern.angle.to_f }
    end

    def one(pattern)
      summary(pattern).merge(
        row_depth: pattern.row_depth.to_f,
        sequence: pattern.sequence.stripes.map { |stripe| stripe(stripe) },
        rows: pattern.rows.map { |row| row(row) },
        colorways: pattern.colorways.map { |colorway| ColorwaySerializer.summary(colorway) }
      )
    end

    def many(patterns)
      patterns.map { |pattern| summary(pattern) }
    end

    # A stripe names the value it draws by rank and not by row id. The rank is
    # what a value is — 0 to n−1, the ground first — and it is the same number
    # in every tool that reads this. A primary key is only a number here.
    def stripe(stripe)
      { position: stripe.position, value: stripe.value.position, width: stripe.width.to_f }
    end

    def row(row)
      {
        position: row.position, height: row.height.to_f, phase: row.phase.to_f,
        color_offset: row.color_offset, mirrored: row.mirrored?,
        width_scale: [ row.width_numerator, row.width_denominator ]
      }
    end
  end
end
