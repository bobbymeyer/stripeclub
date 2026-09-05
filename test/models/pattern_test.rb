require "test_helper"

module Stripeclub
  class PatternTest < ActiveSupport::TestCase
    test "a pattern is named" do
      assert_predicate Pattern.new(slot_count: 2), :invalid?
    end

    # The first principle, guarded rather than written down. A pattern is
    # structure — slots, widths, order, angle, rows — and the moment one of
    # these columns exists someone will fill it in and a pattern will start
    # meaning something different in a colorway than it does on its own.
    test "a pattern carries no colour" do
      assert_empty Pattern.column_names.grep(/colou?r|hex|hue|chroma|palette/)
    end

    test "a pattern has at least one slot, because the ground is a stripe" do
      assert_predicate Pattern.new(name: "Nothing", slot_count: 0), :invalid?
      assert_predicate Pattern.new(name: "Ground", slot_count: 1), :valid?
    end

    # Stripes at 30 degrees and at 210 are the same stripes seen from the other
    # end, so the second spelling is folded onto the first rather than stored.
    # Two patterns that look identical should not compare unequal.
    test "an angle folds into a half turn" do
      assert_equal 30, composed(angle: 210).angle
      assert_equal 90, composed(angle: -90).angle
      assert_equal 0, composed(angle: 180).angle
    end

    test "composing a pattern ranks a value per slot from zero" do
      assert_equal [ 0, 1, 2, 3 ], composed(slot_count: 4).values.map(&:position)
    end

    test "composing a pattern divides the repeat evenly, one stripe per value" do
      pattern = composed(slot_count: 4)

      assert_equal [ 0.25, 0.25, 0.25, 0.25 ], pattern.sequence.stripes.map { |stripe| stripe.width.to_f }
      assert_equal pattern.values.to_a, pattern.sequence.stripes.map(&:value)
    end

    # Slot 0 is the ground and the ground is a stripe, so it is in the repeat
    # from the beginning rather than being what is left when the others are
    # drawn.
    test "the ground takes the first stripe of a composed pattern" do
      pattern = composed(slot_count: 3)

      assert_equal 0, pattern.sequence.stripes.first.value.position
    end

    test "an even division that does not divide still sums to one" do
      pattern = composed(slot_count: 3)

      assert_equal 1, pattern.sequence.total_width
      assert_predicate pattern.sequence, :valid?
    end

    test "adding a value appends a rank and leaves the sequence untouched" do
      pattern = composed(slot_count: 3)
      before = stripe_state(pattern)

      pattern.add_value!

      assert_equal 4, pattern.slot_count
      assert_equal [ 0, 1, 2, 3 ], pattern.values.reload.map(&:position)
      assert_equal before, stripe_state(pattern)
    end

    # The new slot is a slot, not a stripe. Adding one cannot touch the widths,
    # because a fourth stripe in a repeat of three changes all three widths to
    # make room for it, and the table says widths are preserved.
    test "a value added is not yet drawn" do
      pattern = composed(slot_count: 3)

      pattern.add_value!

      assert_equal 3, pattern.sequence.stripes.reload.size
      assert_empty pattern.sequence.stripes.map(&:value) - pattern.values.reload.to_a
      assert_equal [ pattern.values.last ], pattern.values.to_a - pattern.sequence.stripes.map(&:value)
    end

    # The sequence is destroyed before the values because a value refuses to go
    # while a stripe still draws it. That ordering is one line of declaration in
    # the model and nothing about it looks load-bearing, so it is asserted here.
    test "destroying a pattern takes its whole structure with it" do
      pattern = composed(slot_count: 3)

      assert_difference [ "Pattern.count", "Sequence.count" ], -1 do
        assert_difference "Value.count", -3 do
          assert_difference "Stripe.count", -3 do
            assert pattern.destroy
          end
        end
      end
    end

    private
      def composed(name: "Composed", slot_count: 2, **attributes)
        Pattern.create!(name: name, slot_count: slot_count, **attributes)
      end

      def stripe_state(pattern)
        pattern.sequence.stripes.reload.map { |stripe| [ stripe.position, stripe.value_id, stripe.width ] }
      end
  end
end
