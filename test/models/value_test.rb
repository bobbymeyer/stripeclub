require "test_helper"

module Stripeclub
  class ValueTest < ActiveSupport::TestCase
    # A value is a rank and nothing else. Luminance is computed in Stripeclub
    # from the palette a colorway resolves against, so a value that stored one
    # would be storing an answer to a question it is not being asked yet.
    test "a value stores no luminance and no colour" do
      assert_empty Value.column_names.grep(/lum|light|dark|tone|colou?r|hex|oklch/)
    end

    # Held by the foreign key rather than by a validation, so it holds against
    # anything that reaches the table — a validation can be skipped and an
    # association can answer from memory, and this cannot do either.
    test "a value cannot go while a stripe still draws it" do
      pattern = Pattern.create!(name: "Drawn", slot_count: 2)

      assert_raises ActiveRecord::InvalidForeignKey do
        pattern.values.first.destroy
      end
    end

    test "a value ranks uniquely within its pattern" do
      pattern = Pattern.create!(name: "Ranked", slot_count: 2)

      assert_predicate pattern.values.build(position: 0), :invalid?
    end

    test "two patterns rank from zero independently" do
      Pattern.create!(name: "One", slot_count: 2)

      assert_predicate Pattern.create!(name: "Two", slot_count: 2), :persisted?
    end

    test "a rank starts at zero" do
      pattern = Pattern.create!(name: "Ranked", slot_count: 1)

      assert_predicate pattern.values.build(position: -1), :invalid?
    end
  end
end
