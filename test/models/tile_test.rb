require "test_helper"

module Stripeclub
  class TileTest < ActiveSupport::TestCase
    # --- The closing tile ------------------------------------------------
    #
    # Left free, a tile always closes: W sin θ = P and H cos θ = P is a tile for
    # any angle. The unbroken constraint only bites when the tile's shape is
    # fixed — which is what Snap To Tiling is for and what an export like this
    # does not have to accept.
    test "the tile of an upright pattern is one repeat square" do
      tile = tile_for(angle: 90, period: 60)

      assert_in_delta 60, tile.width, 0.001
      assert_in_delta 60, tile.height, 0.001
      assert_predicate tile, :tiles?
    end

    test "the tile of a turned pattern is the repeat over the sine and the cosine" do
      tile = tile_for(angle: 30, period: 60)

      assert_in_delta 120.0, tile.width, 0.01
      assert_in_delta 69.282, tile.height, 0.01
    end

    # The tile that comes out has to satisfy the constraint the tiling model
    # states, or the two are describing different tiles.
    test "the tile that comes out is one the tiling model calls closed" do
      [ 22.5, 30, 45, 61, 100, 155 ].each do |angle|
        tile = tile_for(angle: angle, period: 60)
        tiling = Tiling.new(tile.pattern, mode: :unbroken, width: tile.width, height: tile.height)

        assert_predicate tiling, :seamless?, "#{angle}° gave a tile the tiling model refuses"
        assert_equal Rational(1, 1), tiling.slope_as_ratio
      end
    end

    test "a rowed tile is as wide as its rows need and as deep as the block" do
      pattern = Pattern.create!(name: "Rowed #{rand(1 << 20)}", slot_count: 2, angle: 90, row_depth: 3)
        .divide_into_rows!(3)
      pattern.rows.second.update!(width_numerator: 1, width_denominator: 2)

      tile = Tile.new(ValueScale.new(pattern.reload), period: 60)

      assert_in_delta 60, tile.width, 0.001
      assert_in_delta 180, tile.height, 0.001
    end

    # --- The pattern as a function ---------------------------------------
    #
    # The PNG samples this. It is the second statement of the same geometry the
    # SVG draws as rects, so the two have to agree — these check it against the
    # widths the stripes were given.
    test "an upright pattern reads its stripes off the x axis" do
      tile = tile_for(angle: 90, period: 100, widths: [ 0.25, 0.75 ])

      assert_equal ground(tile), tile.color_at(10, 50)
      assert_equal ground(tile), tile.color_at(24, 50)
      assert_not_equal ground(tile), tile.color_at(26, 50)
      assert_not_equal ground(tile), tile.color_at(99, 50)
    end

    test "a flat pattern reads its stripes off the y axis" do
      tile = tile_for(angle: 0, period: 100, widths: [ 0.25, 0.75 ])

      assert_equal ground(tile), tile.color_at(50, 10)
      assert_not_equal ground(tile), tile.color_at(50, 60)
    end

    # At 45° the phase holds along a line where x falls as y rises. On a page
    # whose y points down that line runs up to the right — which is what "the
    # stripes lean like a forward slash" is, written as arithmetic.
    test "a turned pattern holds its colour along the stripe and changes across it" do
      tile = tile_for(angle: 45, period: 100, widths: [ 0.5, 0.5 ])
      here = tile.color_at(60, 20)

      assert_equal here, tile.color_at(40, 40)
      assert_equal here, tile.color_at(20, 60)

      # The other diagonal is straight across the stripes, so it cannot hold.
      assert_not_equal here, tile.color_at(95, 55)
    end

    test "every point of the tile lands on some stripe" do
      tile = tile_for(angle: 37, period: 60, widths: [ 0.3, 0.7 ])

      (0..20).each do |i|
        (0..20).each do |j|
          x = tile.width * i / 20.0
          y = tile.height * j / 20.0

          assert_not_nil tile.color_at(x, y), "nothing at #{x}, #{y}"
        end
      end
    end

    # The whole point of the tile: what is at x is what is at x + width.
    #
    # Compared as phases and not as colours. A colour lookup steps at every
    # stripe edge, and a point that lands exactly on one — which the tidy
    # fractions of a test do, often — can come back either side of the step
    # depending on the last bit of a float. The phase is the quantity the
    # closure is actually about, and 0.9999 and 0.0001 are next to each other
    # in it rather than a whole repeat apart.
    test "the tile closes on itself in both directions" do
      [ 90, 0, 45, 30, 116.565, 22.5 ].each do |angle|
        tile = tile_for(angle: angle, period: 60, widths: [ 0.35, 0.65 ])

        [ 0.1, 0.37, 0.6, 0.9 ].each do |at|
          x = tile.width * at
          y = tile.height * at

          assert_in_delta 0, apart(tile.phase_at(x, y), tile.phase_at(x + tile.width, y)), 1e-9,
            "#{angle}° seams horizontally at #{at}"
          assert_in_delta 0, apart(tile.phase_at(x, y), tile.phase_at(x, y + tile.height)), 1e-9,
            "#{angle}° seams vertically at #{at}"
        end
      end
    end

    test "a tile that does not close is not quietly wrapped into closing" do
      tile = tile_for(angle: 30, period: 60, widths: [ 0.5, 0.5 ])

      assert_operator apart(tile.phase_at(10, 10), tile.phase_at(10 + (tile.width * 0.4), 10)), :>, 0.01
    end

    test "a rowed tile reads each band through its own row" do
      pattern = Pattern.create!(name: "Shifted #{rand(1 << 20)}", slot_count: 2, angle: 90, row_depth: 2)
        .divide_into_rows!(2)
      pattern.sequence.stripes.each_with_index { |s, i| s.update_column(:width, [ 0.5, 0.5 ][i]) }
      pattern.rows.second.update!(phase: 0.5)

      tile = Tile.new(ValueScale.new(pattern.reload), period: 60)

      # A half-period shift puts the other stripe where the first one was.
      assert_not_equal tile.color_at(10, 20), tile.color_at(10, 90)
    end

    private
      def tile_for(angle:, period: 60, widths: [ 0.5, 0.5 ])
        pattern = Pattern.create!(name: "Tiled #{rand(1 << 30)}", slot_count: widths.size, angle: angle)
        pattern.sequence.stripes.each_with_index { |stripe, i| stripe.update_column(:width, widths[i]) }

        Tile.new(ValueScale.new(pattern.reload), period: period)
      end

      # Phases are a circle: 0.9999 and 0.0001 are a ten-thousandth apart.
      def apart(one, other)
        gap = (one - other).abs

        [ gap, 1 - gap ].min
      end

      def ground(tile)
        tile.color_at(0.01, 0.0)
      end
  end
end
