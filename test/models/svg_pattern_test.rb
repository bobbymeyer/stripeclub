require "test_helper"
require "nokogiri"

module Stripeclub
  class SvgPatternTest < ActiveSupport::TestCase
    # Vertical stripes: the repeat runs along x, and every stripe is the full
    # height of the tile.
    test "vertical stripes lay the repeat out along x" do
      rects = rects_for(angle: 90, widths: [ 0.25, 0.75 ], period: 100)

      assert_equal [ "0", "25" ], rects.map { |rect| rect["x"] }
      assert_equal [ "25", "75" ], rects.map { |rect| rect["width"] }
      assert_equal [ "100", "100" ], rects.map { |rect| rect["height"] }
      assert_equal [ "0", "0" ], rects.map { |rect| rect["y"] }
    end

    # Horizontal stripes are the same repeat turned ninety degrees, laid out
    # directly rather than rotated. The axis-aligned output modes cannot carry a
    # patternTransform, so this geometry is needed whatever step five adds.
    test "horizontal stripes lay the repeat out along y" do
      rects = rects_for(angle: 0, widths: [ 0.25, 0.75 ], period: 100)

      assert_equal [ "0", "25" ], rects.map { |rect| rect["y"] }
      assert_equal [ "25", "75" ], rects.map { |rect| rect["height"] }
      assert_equal [ "100", "100" ], rects.map { |rect| rect["width"] }
      assert_equal [ "0", "0" ], rects.map { |rect| rect["x"] }
    end

    test "there is one rect for every stripe" do
      assert_equal 4, rects_for(angle: 90, widths: [ 0.25, 0.25, 0.25, 0.25 ]).size
    end

    # A sequence of thirds sums to 0.999999, which is as close to one as six
    # places allow. Multiplied out that is a hairline of background showing
    # through every repeat — so the last edge is placed at the period rather
    # than accumulated to it.
    test "the last stripe closes the repeat exactly" do
      third = BigDecimal("0.333333")
      rects = rects_for(angle: 90, widths: [ third, third, third ], period: 90)

      # Without closing the repeat the last edge lands at 89.9999 — a gap of a
      # ten-thousandth, which is a hairline that repeats forever. The tolerance
      # is tighter than that gap on purpose.
      assert_in_delta 90.0, rects.last["x"].to_f + rects.last["width"].to_f, 1e-6
    end

    test "the stripes carry the colorway's colours in order" do
      rects = rects_for(angle: 90, widths: [ 0.5, 0.5 ], palette: %w[ #12120F #FAF8F4 ])

      assert_equal [ "#FAF8F4", "#12120F" ], rects.map { |rect| rect["fill"] }
    end

    test "the tile is the period, measured in user space" do
      element = pattern_element(angle: 90, widths: [ 0.5, 0.5 ], period: 40)

      assert_equal "40", element["width"]
      assert_equal "40", element["height"]
      assert_equal "userSpaceOnUse", element["patternUnits"]
    end

    test "the document fills itself with the pattern it defines" do
      document = parsed(angle: 90, widths: [ 0.5, 0.5 ])
      fill = document.at_css("svg > rect")["fill"]

      assert_equal "url(##{document.at_css("pattern")["id"]})", fill
    end

    test "the pattern is named after the colorway, so two can share a page" do
      colorway = colorway_for(angle: 90, widths: [ 0.5, 0.5 ])
      element = Nokogiri::XML(SvgPattern.new(colorway).to_s).tap(&:remove_namespaces!).at_css("pattern")

      assert_equal "stripeclub-colorway-#{colorway.id}", element["id"]
    end

    # Nothing honest to draw: the pattern has a slot the palette cannot fill,
    # and a render that dropped it or reused a colour would be a guess.
    test "an invalidated colorway will not render" do
      colorway = colorway_for(angle: 90, widths: [ 0.5, 0.5 ])
      colorway.pattern.add_value!

      assert_raises(SvgPattern::NothingToDraw) { SvgPattern.new(colorway.reload).to_s }
    end

    # Any angle, by turning the tile rather than by laying the stripes out along
    # it. patternTransform rotates the tile and the lattice it repeats on
    # together, so the tiles still meet — which is why the reference form never
    # has to warn about an angle.
    test "an angle off the axes turns the tile" do
      element = pattern_element(angle: 45, widths: [ 0.5, 0.5 ])

      assert_equal "rotate(45)", element["patternTransform"]
    end

    test "a turned tile still lays its repeat out along x" do
      rects = rects_for(angle: 30, widths: [ 0.25, 0.75 ], period: 100)

      assert_equal [ "0", "25" ], rects.map { |rect| rect["x"] }
      assert_equal [ "100", "100" ], rects.map { |rect| rect["height"] }
    end

    # The two axes are laid out directly and carry no transform. The geometry is
    # already right, the axis-aligned exports need it in that form anyway, and a
    # rotate(0) on a tile of vertical stripes is a thing to reason about for no
    # gain.
    test "the axes are laid out rather than turned" do
      assert_nil pattern_element(angle: 90, widths: [ 0.5, 0.5 ])["patternTransform"]
      assert_nil pattern_element(angle: 0, widths: [ 0.5, 0.5 ])["patternTransform"]
    end

    # Turning the tile from the upright: at 90° there is nothing to turn, and
    # the further from upright the further it goes. Past the upright it turns
    # the other way, which is what makes the stripes lean the other way.
    #
    # The sign is the whole content of this test. Both signs produce a diagonal
    # and only one produces the diagonal that was asked for; the other is its
    # mirror, and reads as a perfectly good pattern until it is put beside the
    # angle someone typed.
    test "the turn is measured from the upright" do
      assert_equal "rotate(60)", pattern_element(angle: 30, widths: [ 0.5, 0.5 ])["patternTransform"]
      assert_equal "rotate(-45)", pattern_element(angle: 135, widths: [ 0.5, 0.5 ])["patternTransform"]
    end

    test "the document is well formed xml in the svg namespace" do
      document = Nokogiri::XML(svg_for(angle: 90, widths: [ 0.5, 0.5 ])) { |config| config.strict }

      assert_empty document.errors
      assert_equal "http://www.w3.org/2000/svg", document.root.namespace.href
    end

    private
      def colorway_for(angle:, widths:, palette: nil)
        palette ||= grays(widths.size)
        pattern = Pattern.create!(name: "Drawn", slot_count: widths.size, angle: angle)

        pattern.sequence.stripes.each_with_index do |stripe, index|
          stripe.update_column(:width, widths[index])
        end
        pattern.sequence.stripes.reload

        Colorway.create!(pattern: pattern, palette: pandatone_palette(*palette))
      end

      # A palette with a colour per slot, spread across the range so no two
      # stripes come out the same fill by accident.
      def grays(count)
        step = 255 / [ count - 1, 1 ].max

        Array.new(count) { |index| format("#%02X%02X%02X", *([ 255 - (index * step) ] * 3)) }
      end

      def svg_for(period: 100, **attributes)
        SvgPattern.new(colorway_for(**attributes), period: period).to_s
      end

      # Namespaces stripped so the assertions can use plain css selectors. The
      # one test that is about the namespace parses the document itself.
      def parsed(period: 100, **attributes)
        Nokogiri::XML(svg_for(period: period, **attributes)).tap(&:remove_namespaces!)
      end

      def pattern_element(**attributes)
        parsed(**attributes).at_css("pattern")
      end

      def rects_for(**attributes)
        pattern_element(**attributes).css("rect")
      end
  end
end
