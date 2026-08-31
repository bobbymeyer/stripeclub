require "test_helper"

class SequenceTest < ActiveSupport::TestCase
  test "widths sum to one" do
    assert_predicate sequence_of(0.5, 0.25, 0.25), :valid?
  end

  test "a sequence that does not fill the repeat is refused" do
    sequence = sequence_of(0.5, 0.25)

    assert_predicate sequence, :invalid?
    assert_includes sequence.errors[:stripes].to_s, "sum to one"
  end

  test "a sequence that overfills the repeat is refused" do
    assert_predicate sequence_of(0.5, 0.75), :invalid?
  end

  # A third cannot be written in six places. Three of them come to 0.999999,
  # and a rule that refused that would refuse thirds — so the slack is exactly
  # the rounding the storage forces and not a hand-picked epsilon: half a unit
  # in the last place, per stripe, which is the most rounding can cost.
  #
  # Written out rather than divided, because SQLite does not hold a column to
  # its declared scale: dividing here would store a third to twenty places and
  # test the arithmetic of a database rather than the rule.
  test "the rounding six places force is allowed" do
    third = BigDecimal("0.333333")

    assert_equal BigDecimal("0.999999"), sequence_of(third, third, third).total_width
    assert_predicate sequence_of(third, third, third), :valid?
  end

  test "an error larger than rounding explains is refused" do
    assert_predicate sequence_of(0.4, 0.3, 0.3001), :invalid?
  end

  test "the slack does not widen faster than the stripes that earn it" do
    off_by_one_place = Array.new(4, 0.25).tap { |widths| widths[0] += 0.00001 }

    assert_predicate sequence_of(*off_by_one_place), :invalid?
  end

  test "a sequence is at least one stripe, because the ground is a stripe" do
    sequence = sequence_of(1.0)
    sequence.stripes.destroy_all

    assert_predicate sequence.reload, :invalid?
  end

  test "normalising scales widths back onto one" do
    sequence = sequence_of(2.0, 1.0, 1.0)

    sequence.normalize!

    assert_equal [ 0.5, 0.25, 0.25 ], sequence.stripes.reload.map { |stripe| stripe.width.to_f }
    assert_predicate sequence, :valid?
  end

  test "normalising an even division that does not divide still sums to one" do
    sequence = sequence_of(1.0, 1.0, 1.0)

    sequence.normalize!

    assert_equal 1, sequence.reload.total_width
  end
end
