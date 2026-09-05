require "test_helper"

module Stripeclub
  # The public interface: what another tool calls. Plain data out, never a
  # record of the engine's, and the same hashes the API serializes.
  class StripeclubTest < ActiveSupport::TestCase
    setup do
      @pattern = Pattern.create!(name: "Awning", slot_count: 2, angle: 90)
      @pattern.sequence.stripes.each_with_index { |s, i| s.update_column(:width, [ 0.6, 0.4 ][i]) }
      @colorway = Colorway.create!(pattern: @pattern, palette: pandatone_palette("#C1272D", "#FAF8F4"))
    end

    test "patterns are summaries, by name" do
      Pattern.create!(name: "Bias", slot_count: 3, angle: 30)

      assert_equal [ "Awning", "Bias" ], Stripeclub.patterns.map { |p| p[:name] }
      assert_equal %i[ id name slot_count angle ], Stripeclub.patterns.first.keys
    end

    test "a pattern is found by id or by name, with its structure, or is nil" do
      assert_equal [ 0.6, 0.4 ], Stripeclub.pattern("Awning")[:sequence].map { |s| s[:width] }
      assert_equal Stripeclub.pattern("Awning"), Stripeclub.pattern(@pattern.id)
      assert_nil Stripeclub.pattern("nothing by that name")
    end

    test "a colorway carries its rules and the colours they resolve to" do
      assert_equal [ "#FAF8F4", "#C1272D" ], Stripeclub.colorway(@colorway.id)[:colors]
      assert_equal [ @colorway.id ], Stripeclub.colorways.map { |c| c[:id] }
      assert_nil Stripeclub.colorway(0)
    end

    test "a tile is measured in value, or dressed in a colorway" do
      plain = Stripeclub.tile("Awning")
      assert_equal %i[ width height tiles note ], plain.keys
      assert plain[:tiles]

      dressed = Stripeclub.tile_svg("Awning", colorway: @colorway.id)
      assert_includes dressed, "#C1272D"
      assert_nil Stripeclub.tile_svg("Awning", colorway: 0)
    end

    # Nothing that comes back is one of the engine's own objects.
    test "answers with hashes, strings and numbers only" do
      [ Stripeclub.patterns, Stripeclub.pattern("Awning"), Stripeclub.colorways, Stripeclub.colorway(@colorway.id), Stripeclub.tile("Awning") ].each do |answer|
        assert_nothing_raised { JSON.generate(answer) }
      end
    end
  end
end
