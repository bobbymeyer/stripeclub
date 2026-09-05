require "test_helper"

module Stripeclub
  class SnapToTilingTest < ActiveSupport::TestCase
    test "an angle that already tiles is left where it is" do
      pattern = pattern_at(45)

      snap = SnapToTiling.new(pattern)

      assert_not snap.changed?
      assert_in_delta 45, snap.angle, 0.001
    end

    # 30° has a slope of 0.5774, which lies between 1/2 and 2/3 and nearer 1/2.
    # The angle that 1/2 makes is 26.565°.
    test "an angle that does not tile moves to the nearest that does" do
      snap = SnapToTiling.new(pattern_at(30))

      assert_predicate snap, :changed?
      assert_equal Rational(1, 2), snap.slope_as_ratio
      assert_in_delta 26.565, snap.angle, 0.001
    end

    test "snapping is applied to the pattern only when asked" do
      pattern = pattern_at(30)

      assert_in_delta 30, pattern.reload.angle.to_f, 0.001

      SnapToTiling.new(pattern).apply!

      assert_in_delta 26.565, pattern.reload.angle.to_f, 0.001
    end

    test "snapping lands somewhere that tiles" do
      [ 12, 30, 37, 52, 71, 88, 100, 155 ].each do |angle|
        pattern = pattern_at(angle)
        SnapToTiling.new(pattern).apply!

        assert_predicate Tiling.new(pattern.reload, mode: :unbroken), :seamless?,
          "#{angle}° snapped to #{pattern.angle} and still does not tile"
      end
    end

    # Past 90° the stripes lean the other way. The slope is the mirror of the
    # one below it, and snapping has to come back on the same side or the
    # pattern flips while being tidied.
    test "an angle past the upright stays past it" do
      snap = SnapToTiling.new(pattern_at(155))

      assert_operator snap.angle, :>, 90
      assert_operator snap.angle, :<, 180
    end

    # The tile holds a+b repeats corner to corner, so a density that is not a
    # multiple of that cannot close. This is the "adjusting stripe count if
    # needed" of the handoff, read as the count of repeats the tile is asked to
    # span.
    test "a requested density is rounded to what the tile can close on" do
      snap = SnapToTiling.new(pattern_at(45), repeats: 7)

      assert_equal 2, snap.repeats_across
      assert_equal 8, snap.repeats
    end

    test "a density already fitting is left alone" do
      assert_equal 6, SnapToTiling.new(pattern_at(45), repeats: 6).repeats
    end

    test "a density is never rounded down to nothing" do
      assert_equal 3, SnapToTiling.new(pattern_at(63.4349), repeats: 1).repeats
    end

    private
      def pattern_at(angle)
        Pattern.create!(name: "Snap #{angle}", slot_count: 2, angle: angle)
      end
  end
end
