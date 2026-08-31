require "test_helper"

class ValueScaleTest < ActiveSupport::TestCase
  # A pattern with no colorway still has to be looked at — it is the thing
  # being composed, and composition happens before a palette is chosen. The
  # range is its-swiss's own: paper at 98% lightness down to ink at 18%, so a
  # pattern with no palette is drawn in the values of the interface around it.
  test "the ground is paper and the last slot is ink" do
    scale = ValueScale.new(Pattern.create!(name: "Six", slot_count: 6))

    assert_in_delta 0.98, Luminance.of_hex(scale.colors.first.hex), 0.005
    assert_in_delta 0.18, Luminance.of_hex(scale.colors.last.hex), 0.005
  end

  test "the steps between them are even in lightness" do
    scale = ValueScale.new(Pattern.create!(name: "Five", slot_count: 5))
    steps = scale.colors.map { |color| Luminance.of_hex(color.hex) }
    gaps = steps.each_cons(2).map { |lighter, darker| lighter - darker }

    assert_operator gaps.max - gaps.min, :<, 0.01, "the steps should be even"
    assert_equal steps.sort.reverse, steps, "the scale should descend, paper to ink"
  end

  test "a pattern of one slot is all ground" do
    scale = ValueScale.new(Pattern.create!(name: "Ground", slot_count: 1))

    assert_in_delta 0.98, Luminance.of_hex(scale.colors.sole.hex), 0.005
  end

  # It dresses a pattern the way a colorway does, so the renderer does not
  # care which one it was handed.
  test "a value scale draws through the same renderer a colorway does" do
    pattern = Pattern.create!(name: "Drawn", slot_count: 3, angle: 90)

    svg = SvgPattern.new(ValueScale.new(pattern)).to_s

    assert_equal 3, Nokogiri::XML(svg).tap(&:remove_namespaces!).css("pattern rect").size
    assert_includes svg, "stripeclub-pattern-#{pattern.id}"
  end

  test "a value scale is never invalidated, because it has no palette to outgrow" do
    pattern = Pattern.create!(name: "Grown", slot_count: 2)
    pattern.add_value!

    assert_not ValueScale.new(pattern.reload).invalidated?
  end
end
