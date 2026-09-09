require "test_helper"

module Stripeclub
  # Tags are how a pattern is found by something outside Stripeclub: a project
  # asks for everything carrying a tag and gets patterns back beside palettes.
  # That makes the handling load-bearing, so it is normalized in one place and
  # queried in one place, and this is that place under test.
  class PatternTagsTest < ActiveSupport::TestCase
    test "a pattern arrives with no tags rather than with none at all" do
      assert_equal [], Pattern.create!(name: "Awning", slot_count: 2).tags
    end

    test "tags are stripped, downcased and deduplicated, however they arrive" do
      pattern = Pattern.create!(name: "Awning", slot_count: 2, tags: [ "  Brand ", "brand", "2026Summer" ])

      assert_equal %w[ brand 2026summer ], pattern.tags
    end

    # The same writer serves a JSON body and a text field in a form.
    test "a comma-separated string is a list of tags" do
      pattern = Pattern.create!(name: "Awning", slot_count: 2, tag_list: "brand, 2026summer , ")

      assert_equal %w[ brand 2026summer ], pattern.tags
      assert_equal "brand, 2026summer", pattern.tag_list
    end

    # A list is normalized, whatever is in it; anything that is not a list or
    # a line of them is refused rather than guessed at.
    test "tags that are not a list of strings are refused" do
      pattern = Pattern.new(name: "Awning", slot_count: 2, tags: { brand: true })

      assert_not pattern.valid?
      assert_includes pattern.errors[:tags], "must be an array of strings"

      assert_not Pattern.new(name: "Awning", slot_count: 2, tags: 42).valid?
    end

    # Whole tags only: "brand" is not "brands", and a pattern tagged "brands"
    # must not answer a project that asked for "brand".
    test "the tagged scope matches whole tags" do
      awning = Pattern.create!(name: "Awning", slot_count: 2, tags: %w[ brand 2026summer ])
      Pattern.create!(name: "Ticking", slot_count: 2, tags: %w[ brands ])

      assert_equal [ awning ], Pattern.tagged("brand").to_a
      assert_equal [ awning ], Pattern.tagged("  BRAND ").to_a
      assert_empty Pattern.tagged("nothing").to_a
      assert_empty Pattern.tagged("").to_a
    end

    test "every tag in use, for building a filter" do
      Pattern.create!(name: "Awning", slot_count: 2, tags: %w[ brand 2026summer ])
      Pattern.create!(name: "Ticking", slot_count: 2, tags: %w[ brand print ])

      assert_equal %w[ 2026summer brand print ], Pattern.all_tags
    end
  end
end
