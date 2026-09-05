require "test_helper"

module Stripeclub
  class Patterns::ColorwaysControllerTest < ActionDispatch::IntegrationTest
    CATALOGUE = {
      [ 1, "Two Tone" ] => %w[ #FFFFFF #101010 ],
      [ 2, "Deck Chair" ] => %w[ #FAF8F4 #C1272D #E3B505 #12120F ],
      [ 3, "Winter" ] => %w[ #C8DCFF #2B4A8A #111111 ]
    }.freeze

    setup { @pattern = Pattern.create!(name: "Awning", slot_count: 3) }

    # Demoted, not excluded. A slot taken away with "−" brings the rest back
    # into range, so hiding them would hide the thing that changes.
    test "the picker puts what can dress the pattern first and keeps the rest" do
      with_pandatone(palettes: CATALOGUE) do
        get new_pattern_colorway_path(@pattern)

        assert_response :success
        assert_select "section.palettes", 2
        assert_select "section.palettes:first-of-type tbody tr", 2
        assert_select "section.palettes:last-of-type tbody tr", 1
        assert_select "tbody tr", text: /Two Tone/
        assert_select "td", text: "1 short"
      end
    end

    # The handoff's call: the preview is where colour belongs, and what a
    # palette is for here is how its values are spread.
    test "the picker shows a palette in gray, at its own lightnesses" do
      with_pandatone(palettes: CATALOGUE) do
        get new_pattern_colorway_path(@pattern)

        swatches = css_select("section.palettes:first-of-type tbody tr:first-child .palette-swatch")
        grays = swatches.map { |swatch| swatch["style"][/#\h{6}/] }

        assert_equal 4, grays.size
        assert_equal grays.sort.reverse, grays, "the strip should run lightest first"
        assert_not_includes grays, "#C1272D", "the palette's own colours should not be here"
        assert_select ".palette-swatch__name", text: "deck-chair-0"
      end
    end

    test "dressing a pattern takes a snapshot of the palette" do
      with_pandatone(palettes: CATALOGUE) do
        assert_difference "Colorway.count", 1 do
          post pattern_colorways_path(@pattern, palette_id: 2)
        end

        colorway = @pattern.colorways.sole

        assert_redirected_to pattern_path(@pattern)
        assert_equal 2, colorway.palette_id
        assert_equal "Deck Chair", colorway.snapshot.palette_name

        # Four colours into three slots: Auto-Value-Match samples the ranks and
        # keeps both ends, so the ground is still the lightest the palette has
        # and the last slot the darkest. The gold between them is what gives.
        assert_equal 4, colorway.snapshot.size
        assert_equal %w[ #FAF8F4 #C1272D #12120F ], colorway.colors.map(&:hex)
      end
    end

    test "a palette that cannot dress the pattern is refused" do
      with_pandatone(palettes: CATALOGUE) do
        assert_no_difference "Colorway.count" do
          post pattern_colorways_path(@pattern, palette_id: 1)
        end

        assert_redirected_to new_pattern_colorway_path(@pattern)
      end
    end

    # Composing needs nothing from Pandatone; only dressing does. So the picker
    # says what happened rather than falling over, and every page that is not
    # the picker goes on working.
    test "Pandatone not answering is said out loud, not a blank catalogue" do
      with_pandatone(palettes: {}) do
        stub_request(:get, "https://pandatone.test/api/v1/palettes").to_raise(Errno::ECONNREFUSED)

        get new_pattern_colorway_path(@pattern)

        assert_response :success
        assert_select ".empty", text: /did not answer/
      end
    end

    test "with no Pandatone configured at all the picker still renders" do
      get new_pattern_colorway_path(@pattern)

      assert_response :success
      assert_select ".empty", text: /no Pandatone url/
    end

    # Reported, never applied. A design that was finished should not change
    # because someone else opened another tool.
    test "drift is reported and the snapshot is left alone" do
      with_pandatone(palettes: CATALOGUE) do
        post pattern_colorways_path(@pattern, palette_id: 2)
        colorway = @pattern.colorways.sole
        before = colorway.snapshot.palette.colors.map(&:hex)

        stub_palette("https://pandatone.test", 2, "Deck Chair", %w[ #FAF8F4 #000000 #E3B505 #12120F ])

        patch drift_pattern_colorway_path(@pattern, colorway)

        assert_equal before, colorway.reload.snapshot.palette.colors.map(&:hex)
        assert_match(/has moved in Pandatone/, flash[:notice])
      end
    end

    test "a palette that has not moved says so too" do
      with_pandatone(palettes: CATALOGUE) do
        post pattern_colorways_path(@pattern, palette_id: 2)

        patch drift_pattern_colorway_path(@pattern, @pattern.colorways.sole)

        assert_match(/unchanged since this snapshot/, flash[:notice])
      end
    end

    test "a palette that is gone from Pandatone says that" do
      with_pandatone(palettes: CATALOGUE) do
        post pattern_colorways_path(@pattern, palette_id: 2)
        colorway = @pattern.colorways.sole

        with_pandatone(palettes: { [ 1, "Two Tone" ] => %w[ #FFFFFF #101010 ] }) do
          patch drift_pattern_colorway_path(@pattern, colorway)
        end

        assert_match(/no longer has that palette/, flash[:notice])
      end
    end

    test "a colorway can be taken off without touching the pattern" do
      with_pandatone(palettes: CATALOGUE) do
        post pattern_colorways_path(@pattern, palette_id: 2)
        widths = @pattern.sequence.stripes.map(&:width)

        assert_difference "Colorway.count", -1 do
          delete pattern_colorway_path(@pattern, @pattern.colorways.sole)
        end

        assert_equal widths, @pattern.reload.sequence.stripes.map(&:width)
      end
    end
  end
end
