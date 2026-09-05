require "test_helper"

module Stripeclub
  class RowTest < ActiveSupport::TestCase
    test "a pattern has no rows until it is given some" do
      pattern = Pattern.create!(name: "Plain", slot_count: 2)

      assert_empty pattern.rows
      assert_not pattern.rowed?
    end

    test "dividing a pattern into rows gives them even heights that sum to one" do
      pattern = Pattern.create!(name: "Banded", slot_count: 2).divide_into_rows!(4)

      assert_equal [ 0, 1, 2, 3 ], pattern.rows.map(&:position)
      assert_equal [ 0.25, 0.25, 0.25, 0.25 ], pattern.rows.map { |row| row.height.to_f }
      assert_predicate pattern, :rowed?
    end

    test "an even division that does not divide still sums to one" do
      pattern = Pattern.create!(name: "Thirds", slot_count: 2).divide_into_rows!(3)

      assert_equal 1, Proportions.total(pattern.rows.map(&:height))
    end

    # The same rule the stripes keep, for the same reason: a row block whose
    # heights fall short leaves a band of whatever is behind it, every repeat.
    test "row heights sum to one" do
      pattern = Pattern.create!(name: "Short", slot_count: 2).divide_into_rows!(2)

      pattern.rows.first.update_column(:height, 0.25)

      assert_predicate pattern.reload, :invalid?
      assert_includes pattern.errors[:rows].to_s, "sum to one"
    end

    test "a pattern with no rows is not asked to sum to anything" do
      assert_predicate Pattern.create!(name: "Plain", slot_count: 2), :valid?
    end

    test "rows arrive with nothing done to them" do
      row = Pattern.create!(name: "Fresh", slot_count: 2).divide_into_rows!(2).rows.first

      assert_equal 0, row.phase
      assert_equal 0, row.color_offset
      assert_not row.mirrored?
      assert_equal Rational(1, 1), row.width_scale
    end

    # A phase is a proportion of the repeat, so half a period is 0.5. Past a
    # whole one it is the same shift again, which is not a different row.
    test "a phase is a proportion of the repeat" do
      pattern = Pattern.create!(name: "Shifted", slot_count: 2).divide_into_rows!(2)

      assert_predicate row_with(pattern, phase: 0.5), :valid?
      assert_predicate row_with(pattern, phase: 1.5), :invalid?
      assert_predicate row_with(pattern, phase: -0.1), :invalid?
    end

    test "a width scale is a ratio of two positive whole numbers" do
      pattern = Pattern.create!(name: "Scaled", slot_count: 2).divide_into_rows!(2)

      assert_equal Rational(2, 3), row_with(pattern, width_numerator: 2, width_denominator: 3).width_scale
      assert_predicate row_with(pattern, width_numerator: 0), :invalid?
      assert_predicate row_with(pattern, width_denominator: 0), :invalid?
    end

    # The tile has to be a whole number of every row's repeat or the rows seam
    # where it wraps. The least common multiple of the scales is that number,
    # and for fractions it is the lcm of the tops over the gcd of the bottoms.
    test "the tile is the least common multiple of the rows' scales" do
      assert_equal Rational(1, 1), Row.tile_multiple(scaled([ [ 1, 1 ] ]))
      assert_equal Rational(1, 1), Row.tile_multiple(scaled([ [ 1, 2 ], [ 1, 3 ] ]))
      assert_equal Rational(6, 1), Row.tile_multiple(scaled([ [ 2, 1 ], [ 3, 1 ] ]))
      assert_equal Rational(2, 1), Row.tile_multiple(scaled([ [ 2, 3 ], [ 1, 2 ] ]))
    end

    test "every row's repeat divides the tile a whole number of times" do
      scales = [ [ 2, 3 ], [ 1, 2 ], [ 3, 4 ] ]
      multiple = Row.tile_multiple(scaled(scales))

      # Rational#integer? is false even for 9/1, so the denominator is what says
      # a division came out whole.
      scales.each do |numerator, denominator|
        repeats = multiple / Rational(numerator, denominator)

        assert_equal 1, repeats.denominator, "#{numerator}/#{denominator} divides #{multiple} #{repeats} times"
      end
    end

    test "rows go when the pattern does" do
      pattern = Pattern.create!(name: "Doomed", slot_count: 2).divide_into_rows!(3)

      assert_difference "Row.count", -3 do
        pattern.destroy
      end
    end

    private
      def row_with(pattern, **attributes)
        pattern.rows.first.tap { |row| row.assign_attributes(attributes) }
      end

      def scaled(pairs)
        pairs.map { |numerator, denominator| Row.new(width_numerator: numerator, width_denominator: denominator) }
      end
  end
end
