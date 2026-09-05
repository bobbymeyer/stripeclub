require "test_helper"

module Stripeclub
  class PatternsControllerTest < ActionDispatch::IntegrationTest
    test "the index lists patterns and draws each one" do
      Pattern.create!(name: "Awning", slot_count: 2)
      Pattern.create!(name: "Ticking", slot_count: 4)

      get patterns_path

      assert_response :success
      assert_select "table.table tbody tr", 2
      assert_select "svg", 2
      assert_select "svg pattern rect", 6
    end

    # .table and .pagination are the two components its-swiss shipped with no
    # consumer at all — the changelog says so and names them as the ones most
    # likely to move when Stripeclub lands. This is the page that consumes them.
    test "the index paginates once there are more patterns than fit" do
      (PatternsController::PER_PAGE + 2).times { |n| Pattern.create!(name: "Pattern #{n}", slot_count: 2) }

      get patterns_path

      assert_select "table.table tbody tr", PatternsController::PER_PAGE
      assert_select "nav.pagination"
      assert_select "nav.pagination [aria-current=page]", text: "1"

      get patterns_path(page: 2)

      assert_select "table.table tbody tr", 2
    end

    test "a page past the end is brought back to the last one" do
      Pattern.create!(name: "Only", slot_count: 2)

      get patterns_path(page: 99)

      assert_response :success
      assert_select "table.table tbody tr", 1
    end

    test "an empty index says so rather than showing an empty table" do
      get patterns_path

      assert_select ".empty"
      assert_select "table.table", 0
    end

    test "showing a pattern draws it and lists its repeat" do
      pattern = Pattern.create!(name: "Awning", slot_count: 3)

      get pattern_path(pattern)

      assert_response :success
      assert_select "svg pattern rect", 3
      assert_select "table.repeat tbody tr", 3
      assert_select "dl.pairs"
    end

    test "showing a pattern lists its slots, ranked from the ground" do
      pattern = Pattern.create!(name: "Slotted", slot_count: 3)

      get pattern_path(pattern)

      assert_select "section.slots tbody tr", 3
      assert_select "section.slots tbody tr:first-child td", /Ground/
      assert_select "section.slots .slot-swatch", 3
      assert_select "section.slots .slot-swatch--ruled", 0
    end

    test "a slot nothing draws yet says so" do
      pattern = Pattern.create!(name: "Grown", slot_count: 2)
      pattern.add_value!

      get pattern_path(pattern)

      assert_select "section.slots tbody tr", 3
      assert_select "section.slots tbody tr", text: /drawn by nothing/
    end

    # The distinction the handoff asks the editor to show: which parts of the
    # structure are still doing value work. A hatched swatch and the rule named
    # beside it, never the hatch alone.
    test "a colorway marks which slots are bound to a rule rather than to their rank" do
      colorway = colorway_for("Ruled", %w[ #FAF8F4 #808080 #12120F ])
      colorway.bind(colorway.pattern.values.second, kind: :assigned_slot, slot: 0)

      get pattern_path(colorway.pattern)

      assert_select "section.colorways .slot-swatch--ruled", 1
      assert_select "section.colorways tbody tr", text: /Palette slot 0/
      assert_select "section.colorways tbody tr", text: /By rank/
    end

    test "an invalidated colorway is shown as kept rather than drawn" do
      colorway = colorway_for("Outgrown", %w[ #FAF8F4 #12120F ])
      colorway.pattern.add_value!

      get pattern_path(colorway.pattern)

      assert_select "section.colorways", text: /Invalid/
      assert_select "section.colorways svg", 0
    end

    # Tiling is a status, computed per output mode and not enforced. All three
    # modes are reported at once: a pattern that closes as an SVG pattern and
    # not as an unbroken tile is an ordinary pattern, and seeing both together
    # is what makes that readable rather than alarming.
    test "showing a pattern reports its tiling for every output mode" do
      pattern = Pattern.create!(name: "Angled", slot_count: 2, angle: 30)

      get pattern_path(pattern)

      assert_select "table.tiling__modes tbody tr", Tiling::MODES.size
      assert_select "table.tiling__modes tbody tr.tiling--refused td", text: "Doesn't tile"
      assert_select "form[action=?] button", pattern_tiling_path(pattern), text: /Snap to 26\.565°/
    end

    test "a pattern that already closes is offered no snap" do
      pattern = Pattern.create!(name: "Fitted", slot_count: 2, angle: 45)

      get pattern_path(pattern)

      assert_select "tr.tiling--refused", 0
      assert_select "form[action=?]", pattern_tiling_path(pattern), 0
    end

    test "snapping moves the angle to one that closes" do
      pattern = Pattern.create!(name: "Snapped", slot_count: 2, angle: 30)

      patch pattern_tiling_path(pattern)

      assert_redirected_to pattern_path(pattern)
      assert_in_delta 26.565, pattern.reload.angle.to_f, 0.001
      assert_predicate Tiling.new(pattern, mode: :unbroken), :seamless?
    end

    test "snapping a pattern that already closes leaves it alone" do
      pattern = Pattern.create!(name: "Already", slot_count: 2, angle: 45)

      patch pattern_tiling_path(pattern)

      assert_in_delta 45, pattern.reload.angle.to_f, 0.001
    end

    test "an angle off the axes composes and draws" do
      post patterns_path, params: { pattern: { name: "Diagonal", slot_count: 2, angle: 22.5 } }

      pattern = Pattern.order(:created_at).last

      assert_in_delta 22.5, pattern.angle.to_f, 0.001

      get pattern_path(pattern)

      assert_select "svg pattern[patternTransform=?]", "rotate(67.5)"
    end

    test "composing a pattern goes to it" do
      assert_difference "Pattern.count", 1 do
        post patterns_path, params: { pattern: { name: "Ticking", slot_count: 4, angle: 90 } }
      end

      pattern = Pattern.order(:created_at).last

      assert_redirected_to pattern_path(pattern)
      assert_equal 4, pattern.values.count
      assert_equal 4, pattern.sequence.stripes.count
    end

    test "a pattern with no name is refused and says why" do
      assert_no_difference "Pattern.count" do
        post patterns_path, params: { pattern: { name: "", slot_count: 2 } }
      end

      assert_response :unprocessable_content
      assert_select ".errors"
    end

    test "renaming a pattern keeps its structure" do
      pattern = Pattern.create!(name: "Old", slot_count: 3)

      patch pattern_path(pattern), params: { pattern: { name: "New", angle: 0 } }

      assert_redirected_to pattern_path(pattern)
      assert_equal "New", pattern.reload.name
      assert_equal 0, pattern.angle
      assert_equal 3, pattern.values.count
    end

    test "a pattern can be taken away" do
      pattern = Pattern.create!(name: "Doomed", slot_count: 2)

      assert_difference "Pattern.count", -1 do
        delete pattern_path(pattern)
      end

      assert_redirected_to patterns_path
    end

    test "slot count is not editable after composing, because + and - are the way" do
      pattern = Pattern.create!(name: "Fixed", slot_count: 2)

      patch pattern_path(pattern), params: { pattern: { name: "Fixed", slot_count: 5 } }

      assert_equal 2, pattern.reload.slot_count
    end

    # --- Rows ------------------------------------------------------------
    test "a pattern can be broken into rows and put back together" do
      pattern = Pattern.create!(name: "Banded", slot_count: 2)

      post pattern_row_block_path(pattern), params: { count: 4 }

      assert_redirected_to pattern_path(pattern)
      assert_equal 4, pattern.rows.reload.size
      assert_equal 1, Proportions.total(pattern.rows.map(&:height))

      delete pattern_row_block_path(pattern)

      assert_empty pattern.rows.reload
    end

    test "dividing again replaces the rows rather than adding to them" do
      pattern = Pattern.create!(name: "Redivided", slot_count: 2).divide_into_rows!(6)

      post pattern_row_block_path(pattern), params: { count: 3 }

      assert_equal 3, pattern.rows.reload.size
      assert_equal [ 0, 1, 2 ], pattern.rows.map(&:position)
    end

    test "a silly number of rows is brought back to something usable" do
      pattern = Pattern.create!(name: "Greedy", slot_count: 2)

      post pattern_row_block_path(pattern), params: { count: 500 }

      assert_equal Patterns::RowsController::MOST, pattern.rows.reload.size
    end

    # The four transforms are read across the rows — a phase shift is only a
    # shift relative to the band above it — so they are saved together.
    test "the row transforms are saved together" do
      pattern = Pattern.create!(name: "Transformed", slot_count: 2).divide_into_rows!(2)
      first, second = pattern.rows.to_a

      patch pattern_row_block_path(pattern), params: { rows: {
        first.id => { phase: 0, color_offset: 0, mirrored: 0, width_numerator: 1, width_denominator: 1 },
        second.id => { phase: 0.5, color_offset: 2, mirrored: 1, width_numerator: 1, width_denominator: 3 }
      } }

      assert_redirected_to pattern_path(pattern)
      assert_equal 0.5, second.reload.phase.to_f
      assert_equal 2, second.color_offset
      assert_predicate second, :mirrored?
      assert_equal Rational(1, 3), second.width_scale
      assert_equal 0, first.reload.phase.to_f
    end

    test "a phase past a whole period is refused and nothing is saved" do
      pattern = Pattern.create!(name: "Overshifted", slot_count: 2).divide_into_rows!(2)
      first, second = pattern.rows.to_a

      patch pattern_row_block_path(pattern), params: { rows: {
        first.id => { phase: 0.25 },
        second.id => { phase: 4 }
      } }

      assert_equal 0, first.reload.phase.to_f, "the transaction should have taken the first back"
      assert_equal 0, second.reload.phase.to_f
    end

    test "a rowed pattern renders a band per row, each with its own pattern" do
      pattern = Pattern.create!(name: "Rendered", slot_count: 2, angle: 45).divide_into_rows!(3)

      get pattern_path(pattern)

      assert_select "section.rows tbody tr", 3
      assert_select "svg defs pattern", 4
      assert_select "table.tiling__modes tbody tr", text: /Tiles, with rows/
    end

    # A form is not allowed to be a child of a tbody: the browser lifts it out
    # and the table comes apart. One form around the whole table instead.
    test "the row form is not inside the table it lays out" do
      pattern = Pattern.create!(name: "Formed", slot_count: 2).divide_into_rows!(2)

      get pattern_path(pattern)

      assert_select "tbody form", 0
      assert_select "tr form", 0
      assert_select "form table.table tbody tr", 2
    end

    test "a pattern offers its tile in both forms and its colorway in both" do
      colorway = colorway_for("Exported", %w[ #FAF8F4 #12120F ])

      get pattern_path(colorway.pattern)

      assert_select "section.export a[href=?]", pattern_tile_path(colorway.pattern, format: :svg)
      assert_select "section.export a[href*=?]", "format=png", false
      assert_select "section.export a[href=?]",
        pattern_tile_path(colorway.pattern, format: :svg, colorway: colorway.id)
    end

    # --- Round two -------------------------------------------------------
    test "a pattern can be roughened and made clean again" do
      pattern = Pattern.create!(name: "Rough", slot_count: 3)
      clean = pattern.sequence.stripes.map(&:width)

      patch pattern_imperfection_path(pattern), params: {
        imperfection: { wobble: 0.08, variance: 0.3, texture: 0.2, seed: 11 }
      }

      assert_redirected_to pattern_path(pattern)
      assert_predicate pattern.reload.imperfection, :any?
      assert_not_equal clean, pattern.drawn_widths

      delete pattern_imperfection_path(pattern)

      assert_nil pattern.reload.imperfection
      assert_equal clean, pattern.drawn_widths
    end

    # The point of round two: the composition survives being roughened.
    test "roughening never touches the stored composition" do
      pattern = Pattern.create!(name: "Untouched", slot_count: 3)
      stored = pattern.sequence.stripes.map(&:width)

      patch pattern_imperfection_path(pattern), params: { imperfection: { variance: 0.5, seed: 3 } }

      assert_equal stored, pattern.reload.sequence.stripes.map(&:width)
    end

    test "a variance that could take a stripe to nothing is refused and says so" do
      pattern = Pattern.create!(name: "Greedy", slot_count: 3)

      patch pattern_imperfection_path(pattern), params: { imperfection: { variance: 2 } }

      assert_redirected_to pattern_path(pattern)
      assert_nil pattern.reload.imperfection
    end

    test "a roughened pattern draws its filters and says what a raster will miss" do
      pattern = Pattern.create!(name: "Filtered", slot_count: 2)
      Imperfection.create!(pattern: pattern, wobble: 0.1, texture: 0.2, seed: 5)

      get pattern_path(pattern.reload)

      assert_select "svg filter feTurbulence[stitchTiles=stitch]", 2
      assert_select "svg filter feDisplacementMap"
      assert_match(/carries the geometry and not the filters/, Tile.new(ValueScale.new(pattern)).note)
    end

    private
      # A colorway built from a palette written out here rather than fetched.
      # Choosing a palette needs Pandatone; everything after the choosing does
      # not, and these tests are about everything after.
      def colorway_for(name, hexes)
        pattern = Pattern.create!(name: name, slot_count: hexes.size)

        colors = hexes.each_with_index.map do |hex, index|
          Pandatone::Color.new(id: index, name: "Colour #{index}", hex: hex,
            red: hex[1..2].to_i(16), green: hex[3..4].to_i(16), blue: hex[5..6].to_i(16))
        end

        Colorway.create!(pattern: pattern,
          palette: Pandatone::Palette.new(id: 1, name: "Seeded", colors: colors))
      end
  end
end
