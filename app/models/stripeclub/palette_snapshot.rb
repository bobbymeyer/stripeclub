# What the palette held at the moment it was chosen.
module Stripeclub
  class PaletteSnapshot < ApplicationRecord
    belongs_to :colorway, inverse_of: :snapshot

    validates :taken_at, presence: true

    def size
      colors.size
    end

    # Read back through the same reader that reads Pandatone's wire format, so
    # ranking a snapshot and ranking a live palette are one piece of code.
    def palette
      Pandatone::Palette.from_json(
        "id" => colorway&.palette_id, "name" => palette_name, "colors" => colors
      )
    end

    # Whether Pandatone's palette has moved since. Identity and value in the
    # order they were in: a colour edited, added, removed, or moved is all drift,
    # because Assigned Slot names a position and a reordered palette moves
    # colours without changing any of them.
    #
    # It reports. Applying drift is a decision, and a design that was finished
    # should not change because someone else opened another tool.
    def drifted_from?(palette)
      fingerprint(self.palette.colors) != fingerprint(palette.colors)
    end

    private
      def fingerprint(colors)
        colors.map { |color| [ color.id, color.hex ] }
      end
  end
end
