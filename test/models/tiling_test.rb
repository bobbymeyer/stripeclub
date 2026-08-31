require "test_helper"

class TilingTest < ActiveSupport::TestCase
  # The reference form. patternTransform rotates the tile and the lattice it
  # repeats on together, so the tiles still meet however far it is turned.
  # There is no angle it can be asked about that it has to refuse.
  test "the svg pattern tiles at every angle and never warns" do
    [ 0, 30, 45, 90, 137.5, 179.999 ].each do |angle|
      tiling = tiling_for(angle, mode: :svg_pattern)

      assert_predicate tiling, :seamless?, "#{angle}° should tile as an svg pattern"
      assert_equal :seamless, tiling.status
    end
  end

  # An axis-aligned tile cannot carry a transform, so the angle has to fit the
  # tile. On a square tile that means tan θ has to be a ratio of small whole
  # numbers, and 45° is the one everybody knows: tan 45° = 1 = 1/1.
  test "an unbroken tile takes an angle whose slope is a small ratio" do
    assert_predicate tiling_for(45), :seamless?
    assert_equal Rational(1, 1), tiling_for(45).slope_as_ratio

    assert_predicate tiling_for(63.4349), :seamless?
    assert_equal Rational(2, 1), tiling_for(63.4349).slope_as_ratio
  end

  test "an unbroken tile refuses an angle that lands between the ratios" do
    tiling = tiling_for(30)

    assert_not tiling.seamless?
    assert_equal :does_not_tile, tiling.status
    assert_match(/26\.565°/, tiling.reason)
    assert_match(/\A30° /, tiling.reason)
    assert_match(%r{slope of 1/2}, tiling.reason)
  end

  # Both axes tile any rectangle, because the pattern is constant along one of
  # them: the tile is one repeat wide, or one repeat tall, and nothing has to
  # line up diagonally at all.
  test "the two axes tile an unbroken rectangle whatever its shape" do
    assert_predicate tiling_for(0, width: 3.0, height: 7.0), :seamless?
    assert_predicate tiling_for(90, width: 3.0, height: 7.0), :seamless?
  end

  # tan θ = (b·H)/(a·W). Change the tile's shape and the angle that fits it
  # changes with it — the slope is measured against the tile, not the page.
  #
  # 71.565° is 3/1 on a square. On a tile twice as wide it would need 6/1,
  # and six is not a small integer, so the same angle stops closing.
  test "the angle that fits depends on the shape of the tile" do
    assert_predicate tiling_for(71.565, width: 1.0, height: 1.0), :seamless?
    assert_equal Rational(3, 1), tiling_for(71.565, width: 1.0, height: 1.0).slope_as_ratio

    assert_not tiling_for(71.565, width: 2.0, height: 1.0).seamless?
  end

  test "a tile twice as wide takes the angle that is half as steep" do
    fitted = tiling_for(degrees(Math.atan(0.5)), width: 2.0, height: 1.0)

    assert_predicate fitted, :seamless?
    assert_equal Rational(1, 1), fitted.slope_as_ratio
  end

  # a + b: the number of stripe repeats crossed going corner to opposite
  # corner. It is how many repeats the tile has to hold, and what a requested
  # density has to be a multiple of.
  test "a tile holds as many repeats across as the two parts of its ratio" do
    assert_equal 2, tiling_for(45).repeats_across
    assert_equal 3, tiling_for(63.4349).repeats_across
    assert_equal 1, tiling_for(0).repeats_across
    assert_equal 1, tiling_for(90).repeats_across
  end

  # Rows carry the vertical seam, so the angle is free again and only the
  # horizontal period has to be worked out: P over sin θ.
  test "a row-broken tile takes any angle and says what its period is" do
    tiling = tiling_for(30, mode: :row_broken)

    assert_predicate tiling, :seamless?
    assert_equal :seamless_with_rows, tiling.status
    assert_in_delta 120.0, tiling.horizontal_period(60), 0.001
  end

  test "a row-broken tile at the horizontal has no horizontal period to find" do
    assert_nil tiling_for(0, mode: :row_broken).horizontal_period(60)
  end

  test "every mode says which one it is answering about" do
    assert_raises(ArgumentError) { tiling_for(45, mode: :guesswork) }
  end

  private
    def degrees(radians)
      radians * 180 / Math::PI
    end

    def tiling_for(angle, mode: :unbroken, width: 1.0, height: 1.0)
      pattern = Pattern.create!(name: "Angled #{angle}#{mode}#{width}", slot_count: 2, angle: angle)

      Tiling.new(pattern, mode: mode, width: width, height: height)
    end
end
