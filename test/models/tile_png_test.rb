require "test_helper"

module Stripeclub
  class TilePngTest < ActiveSupport::TestCase
    # Dimensions do not need a single pixel written, which is why the size rules
    # are asked about here and not through a rendered image.
    test "the scale says how many pixels a unit of the tile is worth" do
      png = TilePng.new(upright, period: 60, scale: 3)

      assert_equal 180, png.width
      assert_equal 180, png.height
    end

    test "a scale that would draw a poster is brought back to a tile" do
      png = TilePng.new(upright, period: 400, scale: 16)

      assert_operator [ png.width, png.height ].max, :<=, TilePng::MOST_PIXELS
      assert_operator [ png.width, png.height ].max, :>, TilePng::MOST_PIXELS - 2
    end

    # The sampler and the encoder together, on the smallest picture that can say
    # anything: a quarter of the repeat is the ground and the rest is not.
    test "the pixels come out where the stripes are" do
      image = ChunkyPNG::Image.from_blob(TilePng.new(upright(widths: [ 0.25, 0.75 ]), period: 40, scale: 1).to_blob)

      assert_equal 40, image.width

      ground = ChunkyPNG::Color.to_hex(image[2, 20], false).upcase
      rest = ChunkyPNG::Color.to_hex(image[30, 20], false).upcase

      assert_equal "#F8F8F8", ground
      assert_equal "#121212", rest
    end

    # An edge that crosses a pixel gets its share of it. One sample a pixel
    # gives a staircase; this is what makes it an edge.
    test "an angled edge is averaged rather than stepped" do
      image = ChunkyPNG::Image.from_blob(TilePng.new(turned, period: 40, scale: 2).to_blob)

      shades = image.pixels.map { |pixel| ChunkyPNG::Color.r(pixel) }.uniq

      assert_operator shades.size, :>, 2, "only the two stripe colours came out — nothing was averaged"
    end

    private
      def upright(widths: [ 0.5, 0.5 ])
        ValueScale.new(pattern_of(90, widths))
      end

      def turned
        ValueScale.new(pattern_of(45, [ 0.5, 0.5 ]))
      end

      def pattern_of(angle, widths)
        Pattern.create!(name: "Png #{rand(1 << 30)}", slot_count: widths.size, angle: angle).tap do |pattern|
          pattern.sequence.stripes.each_with_index { |stripe, i| stripe.update_column(:width, widths[i]) }
          pattern.sequence.stripes.reload
        end
      end
  end
end
