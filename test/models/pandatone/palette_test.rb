require "test_helper"

class Pandatone::PaletteTest < ActiveSupport::TestCase
  # Lightest first, and slot 0 is the ground. its-swiss numbers its own value
  # scale the same way round — --value-0 is paper at 98% lightness and
  # --value-5 is ink at 18% — so a pattern dressed by rank reads the way the
  # library it is dressed in reads.
  test "colours rank lightest first" do
    palette = palette_of("#12120F", "#FAF8F4", "#808080")

    assert_equal [ "#FAF8F4", "#808080", "#12120F" ], palette.ranked.map(&:hex)
  end

  test "ranking is by how light a colour looks, not by its channels" do
    palette = palette_of("#0000FF", "#FFFF00")

    assert_equal [ "#FFFF00", "#0000FF" ], palette.ranked.map(&:hex)
  end

  # A colorway resolves its values against these ranks and re-resolves them
  # every time it renders. Two colours of equal lightness that swapped places
  # between renders would move a stripe for no reason anyone could see.
  test "ranking is settled when two colours weigh the same" do
    palette = palette_of("#FF0000", "#FF0000", "#FF0000")

    assert_equal palette.ranked.map(&:id), palette.ranked.map(&:id)
    assert_equal [ 1, 2, 3 ], palette.ranked.map(&:id)
  end

  test "a palette serves a pattern when it has a colour for every slot" do
    palette = palette_of("#000000", "#FFFFFF", "#808080")

    assert palette.serves?(3)
    assert palette.serves?(2)
    assert_not palette.serves?(4)
  end

  # Increment steps one colour per stripe and wraps, so the run only closes on
  # itself when the number of stripes is a whole number of times round the
  # palette. Anything else lands mid-cycle at the seam.
  test "a palette cycles cleanly when its size divides the stripe count" do
    palette = palette_of("#000000", "#FFFFFF", "#808080")

    assert palette.cycles_cleanly?(6)
    assert palette.cycles_cleanly?(3)
    assert_not palette.cycles_cleanly?(4)
  end

  test "an empty palette cycles nothing" do
    assert_not Pandatone::Palette.new(id: 1, name: "Empty").cycles_cleanly?(4)
  end

  test "a colour with no rgb is measured from its hex" do
    color = Pandatone::Color.from_json({ "id" => 1, "name" => "Cream", "hex" => "#FAF8F4" })

    assert_in_delta 0.98, color.luminance, 0.005
  end

  private
    def palette_of(*hexes)
      colors = hexes.each_with_index.map do |hex, index|
        Pandatone::Color.from_json(
          "id" => index + 1, "name" => "Colour #{index}", "hex" => hex,
          "rgb" => { "r" => hex[1..2].to_i(16), "g" => hex[3..4].to_i(16), "b" => hex[5..6].to_i(16) }
        )
      end

      Pandatone::Palette.new(id: 1, name: "Sample", colors: colors)
    end
end
