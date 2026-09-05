require "test_helper"

module Stripeclub
  class ColorwayTest < ActiveSupport::TestCase
    # p == n, so each value takes the colour at its own rank and the ground
    # takes the lightest.
    test "auto value match gives each value the colour at its rank" do
      colorway = colorway_for(slot_count: 3, palette: %w[ #12120F #FAF8F4 #808080 ])

      assert_equal [ "#FAF8F4", "#808080", "#12120F" ], colorway.colors.map(&:hex)
    end

    test "slot zero takes the lightest colour, because slot zero is the ground" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #12120F #FAF8F4 ])

      assert_equal "#FAF8F4", colorway.color_for(first_stripe(colorway)).hex
      assert_equal 0, first_stripe(colorway).value.position
    end

    # Nothing points at a value once its stripes and its rules are gone, which
    # is the order the pattern destroys them in. A colorway left behind would
    # also leave a snapshot and a palette id belonging to a pattern that is not
    # there.
    test "destroying a pattern takes its colorways with it" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #FAF8F4 #12120F ])
      colorway.bind(colorway.pattern.values.first, kind: :assigned_slot, slot: 1)

      assert_difference [ "Colorway.count", "PaletteSnapshot.count", "ValueRule.count" ], -1 do
        assert colorway.pattern.destroy
      end
    end

    # p > n, so the ranks are sampled. Both ends are kept: the ground stays the
    # lightest colour the palette has and the last slot stays the darkest, which
    # is the range the palette was chosen for.
    test "a palette with more colours than slots is sampled evenly by rank" do
      six = %w[ #FFFFFF #DDDDDD #BBBBBB #999999 #555555 #000000 ]

      assert_equal %w[ #FFFFFF #000000 ], colorway_for(slot_count: 2, palette: six).colors.map(&:hex)
      assert_equal %w[ #FFFFFF #999999 #000000 ], colorway_for(slot_count: 3, palette: six).colors.map(&:hex)
      assert_equal six, colorway_for(slot_count: 6, palette: six).colors.map(&:hex)
    end

    test "a single slot takes the lightest colour" do
      colorway = colorway_for(slot_count: 1, palette: %w[ #12120F #FAF8F4 ])

      assert_equal [ "#FAF8F4" ], colorway.colors.map(&:hex)
    end

    test "a colorway holds the palette it was given" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #FAF8F4 #12120F ])

      assert_equal 7, colorway.palette_id
      assert_equal "Sample", colorway.snapshot.palette_name
    end

    # Kept and marked, never deleted: the pattern grew a slot the palette cannot
    # fill, and the colorway is still the record of a decision someone made.
    test "a pattern that outgrows its palette invalidates the colorway" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #FAF8F4 #12120F ])

      assert_not colorway.invalidated?

      colorway.pattern.add_value!

      assert colorway.reload.invalidated?
      assert_predicate colorway, :persisted?
    end

    # Derived rather than stored, and this is why. A stored mark would have to
    # be found and cleared by whatever ran "−", and anything that changed the
    # pattern by another route would leave it lying. Asking the question fresh
    # cannot go stale, and reviving is free.
    test "taking the slot away again revives the colorway" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #FAF8F4 #12120F ])
      colorway.pattern.add_value!
      assert colorway.reload.invalidated?

      colorway.pattern.remove_value!

      assert_not colorway.reload.invalidated?
    end

    test "an invalidated colorway resolves no colours rather than guessing" do
      colorway = colorway_for(slot_count: 2, palette: %w[ #FAF8F4 #12120F ])
      colorway.pattern.add_value!

      assert_empty colorway.reload.colors
    end

    test "a colorway needs a palette that can serve the pattern it is made for" do
      pattern = Pattern.create!(name: "Wide", slot_count: 3)

      colorway = Colorway.new(pattern: pattern, palette: pandatone_palette("#FAF8F4"))

      assert_predicate colorway, :invalid?
    end

    private
      def colorway_for(slot_count:, palette:)
        Colorway.create!(
          pattern: Pattern.create!(name: "Pattern #{slot_count}", slot_count: slot_count),
          palette: pandatone_palette(*palette)
        )
      end

      def first_stripe(colorway)
        colorway.pattern.sequence.stripes.first
      end
  end
end
