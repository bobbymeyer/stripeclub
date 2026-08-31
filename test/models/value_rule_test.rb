require "test_helper"

class ValueRuleTest < ActiveSupport::TestCase
  # Three colours whose stored order is not their order by lightness. Every
  # test below turns on the difference: Auto-Value-Match reads the rank, and
  # the other three read the position in the palette.
  UNSORTED = %w[ #12120F #FAF8F4 #808080 ].freeze

  test "a value with nothing said about it is bound to its rank" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    assert_predicate colorway.rule_for(slot(colorway, 0)), :auto_value_match?
    assert_predicate colorway.rule_for(slot(colorway, 0)), :binds_to_rank?
  end

  test "auto value match reads the rank, so the ground takes the lightest" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    assert_equal [ "#FAF8F4", "#808080", "#12120F" ], colorway.colors.map(&:hex)
  end

  # palette[i], and i is where the colour sits in the palette — not where it
  # sits once ranked. Drift is order-sensitive for exactly this reason.
  test "an assigned slot reads the palette's own order" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    colorway.bind(slot(colorway, 0), kind: :assigned_slot, slot: 0)

    assert_equal "#12120F", colorway.reload.colors.first.hex
    assert_not colorway.rule_for(slot(colorway, 0)).binds_to_rank?
  end

  test "an assigned slot must name a colour the palette has" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    assert_predicate rule(colorway, kind: :assigned_slot, slot: 3), :invalid?
    assert_predicate rule(colorway, kind: :assigned_slot, slot: -1), :invalid?
    assert_predicate rule(colorway, kind: :assigned_slot, slot: 2), :valid?
  end

  # Seeded per tile: the same tile has to draw the same way every time it is
  # rendered, or it is not a pattern — the repeat next to it would differ.
  test "a random draw is the same draw every time" do
    colorway = colorway_of(UNSORTED, slot_count: 3)
    colorway.bind(slot(colorway, 1), kind: :random, subset: [ 0, 2 ], seed: 4242)

    first = colorway.reload.colors.map(&:hex)
    second = Colorway.find(colorway.id).colors.map(&:hex)

    assert_equal first, second
  end

  test "a random draw only ever lands in the subset it was given" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)
    ground = slot(colorway, 0)

    (1..40).each do |seed|
      colorway.bind(ground, kind: :random, subset: [ 1, 3 ], seed: seed)

      assert_includes %w[ #DDDDDD #000000 ], colorway.reload.colors.first.hex,
        "seed #{seed} drew outside the subset"
    end
  end

  test "two seeds draw differently" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)
    wide = (0..3).to_a

    draws = [ 1, 2, 3, 4, 5, 6 ].map do |seed|
      colorway.bind(slot(colorway, 0), kind: :random, subset: wide, seed: seed)
      colorway.reload.colors.first.hex
    end

    assert_operator draws.uniq.size, :>, 1, "every seed drew the same colour"
  end

  test "a random rule needs a subset and a seed" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    assert_predicate rule(colorway, kind: :random, subset: [], seed: 1), :invalid?
    assert_predicate rule(colorway, kind: :random, subset: [ 9 ], seed: 1), :invalid?
    assert_predicate rule(colorway, kind: :random, subset: [ 0, 1 ], seed: 1), :valid?
  end

  test "a random rule seeds itself rather than drawing differently each time" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    made = colorway.bind(slot(colorway, 0), kind: :random, subset: [ 0, 1 ])

    assert_kind_of Integer, made.seed
  end

  # palette[(start + k·step) mod p], k counting stripes along the repeat.
  test "increment steps one colour per stripe and wraps" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)
    colorway.pattern.values.each { |value| colorway.bind(value, kind: :increment, start: 0, step: 1) }

    assert_equal %w[ #FFFFFF #DDDDDD #999999 #000000 ], colorway.reload.colors.map(&:hex)
  end

  test "increment starts where it is told and takes the step it is given" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)
    colorway.pattern.values.each { |value| colorway.bind(value, kind: :increment, start: 1, step: 2) }

    assert_equal %w[ #DDDDDD #000000 #DDDDDD #000000 ], colorway.reload.colors.map(&:hex)
  end

  # With step 1 the cycle is the whole palette, so the repeat only closes when
  # the stripes are a whole number of times round it. With step 2 over four
  # colours the cycle is two, and half as many stripes will do.
  test "a cycle is the palette over what it shares with the step" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)

    assert_equal 4, rule(colorway, kind: :increment, start: 0, step: 1).cycle_length
    assert_equal 2, rule(colorway, kind: :increment, start: 0, step: 2).cycle_length
    assert_equal 4, rule(colorway, kind: :increment, start: 0, step: 3).cycle_length
  end

  test "increment closes when its cycle divides the stripes" do
    colorway = colorway_of(%w[ #FFFFFF #DDDDDD #999999 #000000 ], slot_count: 4)

    assert rule(colorway, kind: :increment, start: 0, step: 1).closes?(4)
    assert rule(colorway, kind: :increment, start: 0, step: 1).closes?(8)
    assert_not rule(colorway, kind: :increment, start: 0, step: 1).closes?(6)
    assert rule(colorway, kind: :increment, start: 0, step: 2).closes?(6)
  end

  test "an increment must move and must start inside the palette" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    assert_predicate rule(colorway, kind: :increment, start: 0, step: 0), :invalid?
    assert_predicate rule(colorway, kind: :increment, start: 5, step: 1), :invalid?
  end

  # Each value carries its own rule, so a structure can be part rank and part
  # rule — which is the whole reason the editor marks which is which.
  test "values are resolved one rule at a time" do
    colorway = colorway_of(UNSORTED, slot_count: 3)

    colorway.bind(slot(colorway, 1), kind: :assigned_slot, slot: 0)

    assert_equal [ "#FAF8F4", "#12120F", "#12120F" ], colorway.reload.colors.map(&:hex)
  end

  test "one rule per value, however often it is set" do
    colorway = colorway_of(UNSORTED, slot_count: 3)
    ground = slot(colorway, 0)

    colorway.bind(ground, kind: :assigned_slot, slot: 0)
    colorway.bind(ground, kind: :assigned_slot, slot: 2)

    assert_equal 1, colorway.reload.rules.count
    assert_equal "#808080", colorway.colors.first.hex
  end

  private
    def colorway_of(hexes, slot_count:)
      pattern = Pattern.create!(name: "Ruled #{hexes.size}#{slot_count}#{rand(1 << 20)}", slot_count: slot_count)

      Colorway.create!(pattern: pattern, palette: pandatone_palette(*hexes))
    end

    def slot(colorway, position)
      colorway.pattern.values.find_by!(position: position)
    end

    def rule(colorway, kind:, **settings)
      ValueRule.new(colorway: colorway, value: slot(colorway, 0), kind: kind, **settings)
    end
end
