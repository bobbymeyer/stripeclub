require "test_helper"
require "nokogiri"

module Stripeclub
  class SvgImperfectionTest < ActiveSupport::TestCase
    test "a clean pattern carries no filter at all" do
      document = render

      assert_empty document.css("filter")
      assert_nil document.at_css("svg > rect")["filter"]
    end

    # stitchTiles is the whole reason this can be used on a repeat: without it
    # the noise is a field that happens to be under the pattern, and it seams
    # wherever the filter tile does.
    test "wobbly edges are turbulence displacing the pattern, stitched so the noise tiles" do
      document = render(wobble: 0.1, wobble_frequency: 0.03, wobble_octaves: 3)

      turbulence = document.at_css("filter feTurbulence")

      assert_equal "fractalNoise", turbulence["type"]
      assert_equal "0.03", turbulence["baseFrequency"]
      assert_equal "3", turbulence["numOctaves"]
      assert_equal "stitch", turbulence["stitchTiles"]

      displacement = document.at_css("filter feDisplacementMap")

      assert_equal "SourceGraphic", displacement["in"]
      assert_equal turbulence["result"], displacement["in2"]
      assert_equal "R", displacement["xChannelSelector"]
      assert_equal "G", displacement["yChannelSelector"]
    end

    # A proportion of the repeat, not a number of pixels: the same pattern drawn
    # at twice the size should wobble twice as far, or it is a different pattern.
    test "how far an edge is pushed is a proportion of the repeat" do
      assert_equal "6", displacement_scale(period: 60, wobble: 0.1)
      assert_equal "12", displacement_scale(period: 120, wobble: 0.1)
      assert_equal "12", displacement_scale(period: 60, wobble: 0.2)
    end

    # The filtered paint runs well outside the frame, because a displacement
    # pulls colour in from beside itself and at the edge of a rect that is
    # exactly the frame there is nothing beside it to pull.
    test "the paint a wobble displaces reaches past the frame" do
      paint = render(wobble: 0.1).at_css("svg > g > rect")

      assert_equal "-50%", paint["x"]
      assert_equal "200%", paint["width"]
    end

    # And is then clipped back to it. An svg root is meant to clip to its
    # viewport, and inline in a page it does not always — so the file says so
    # rather than trusting whatever opens it.
    test "the paint is clipped back to the frame" do
      document = render(wobble: 0.1, period: 100)
      group = document.at_css("svg > g")

      assert_equal "url(#stripeclub-pattern-#{Pattern.last.id}-frame)", group["clip-path"]

      clip = document.at_css("clipPath rect")

      assert_equal "240", clip["width"]
      assert_equal "240", clip["height"]
    end

    test "a clean pattern needs no clip" do
      assert_empty render.css("clipPath")
    end

    test "texture is a stitched noise multiplied over the whole" do
      document = render(texture: 0.3, texture_frequency: 0.9)

      layer = document.css("svg > rect").last

      assert_equal "0.3", layer["opacity"]
      assert_match(/multiply/, layer["style"])

      noise = document.at_css("filter[id$=texture] feTurbulence")

      assert_equal "0.9", noise["baseFrequency"]
      assert_equal "stitch", noise["stitchTiles"]
      assert_equal "0", document.at_css("filter[id$=texture] feColorMatrix")["values"]
    end

    test "the filters are named after the pattern, so two can share a page" do
      pattern = roughened(wobble: 0.1, texture: 0.2)
      document = parse(SvgPattern.new(ValueScale.new(pattern), id: "mine").to_s)

      assert_equal %w[ mine-wobble mine-texture ].sort, document.css("filter").map { |f| f["id"] }.sort
    end

    # Variance is geometry, so it moves the rects rather than filtering them —
    # and the repeat still closes, which is the rule it is held to everywhere.
    test "variance moves the stripes and still closes the repeat" do
      clean = render(period: 100).css("pattern rect").map { |r| r["width"].to_f }
      varied = render(period: 100, variance: 0.4).css("pattern rect").map { |r| r["width"].to_f }

      assert_not_equal clean, varied
      assert_in_delta 100.0, varied.sum, 0.001
    end

    private
      def roughened(**attributes)
        pattern = Pattern.create!(name: "Rough #{rand(1 << 30)}", slot_count: 3, angle: 90)
        Imperfection.create!(pattern: pattern, seed: 99, **attributes) if attributes.any?

        pattern.reload
      end

      def render(period: 60, **attributes)
        parse(SvgPattern.new(ValueScale.new(roughened(**attributes)), period: period).to_s)
      end

      def displacement_scale(period:, **attributes)
        render(period: period, **attributes).at_css("feDisplacementMap")["scale"]
      end

      def parse(svg)
        Nokogiri::XML(svg).tap(&:remove_namespaces!)
      end
  end
end
