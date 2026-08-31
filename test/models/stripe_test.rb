require "test_helper"

class StripeTest < ActiveSupport::TestCase
  setup do
    @pattern = Pattern.create!(name: "Host", slot_count: 2)
    @sequence = @pattern.sequence
  end

  # No blank stripes: a stripe of no width is a stripe that is not there, and
  # a repeat is easier to read with it removed than with it kept at zero.
  test "a stripe has width" do
    assert_predicate stripe(width: 0), :invalid?
    assert_predicate stripe(width: -0.5), :invalid?
  end

  test "a stripe cannot be wider than the repeat" do
    assert_predicate stripe(width: 1.5), :invalid?
  end

  test "a stripe draws a value of its own pattern" do
    other = Pattern.create!(name: "Elsewhere", slot_count: 2)

    borrowed = stripe(value: other.values.first)

    assert_predicate borrowed, :invalid?
    assert_includes borrowed.errors[:value].to_s, "another pattern"
  end

  test "a stripe is ordered within its sequence" do
    assert_equal [ 0, 1 ], @sequence.stripes.map(&:position)
  end

  private
    def stripe(**attributes)
      @sequence.stripes.build({ value: @pattern.values.first, width: 0.5, position: 9 }.merge(attributes))
    end
end
