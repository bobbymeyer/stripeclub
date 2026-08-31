require "test_helper"

class PatternsControllerTest < ActionDispatch::IntegrationTest
  test "the index lists patterns and draws each one" do
    Pattern.create!(name: "Awning", slot_count: 2)
    Pattern.create!(name: "Ticking", slot_count: 4)

    get patterns_path

    assert_response :success
    assert_select "table.table tbody tr", 2
    assert_select "svg", 2
    assert_select "svg pattern rect", 6
  end

  # .table and .pagination are the two components its-swiss shipped with no
  # consumer at all — the changelog says so and names them as the ones most
  # likely to move when Stripeclub lands. This is the page that consumes them.
  test "the index paginates once there are more patterns than fit" do
    (PatternsController::PER_PAGE + 2).times { |n| Pattern.create!(name: "Pattern #{n}", slot_count: 2) }

    get patterns_path

    assert_select "table.table tbody tr", PatternsController::PER_PAGE
    assert_select "nav.pagination"
    assert_select "nav.pagination [aria-current=page]", text: "1"

    get patterns_path(page: 2)

    assert_select "table.table tbody tr", 2
  end

  test "a page past the end is brought back to the last one" do
    Pattern.create!(name: "Only", slot_count: 2)

    get patterns_path(page: 99)

    assert_response :success
    assert_select "table.table tbody tr", 1
  end

  test "an empty index says so rather than showing an empty table" do
    get patterns_path

    assert_select ".empty"
    assert_select "table.table", 0
  end

  test "showing a pattern draws it and lists its repeat" do
    pattern = Pattern.create!(name: "Awning", slot_count: 3)

    get pattern_path(pattern)

    assert_response :success
    assert_select "svg pattern rect", 3
    assert_select "table.repeat tbody tr", 3
    assert_select "dl.pairs"
  end

  # Tiling is a status, computed per output mode and not enforced. All three
  # modes are reported at once: a pattern that closes as an SVG pattern and
  # not as an unbroken tile is an ordinary pattern, and seeing both together
  # is what makes that readable rather than alarming.
  test "showing a pattern reports its tiling for every output mode" do
    pattern = Pattern.create!(name: "Angled", slot_count: 2, angle: 30)

    get pattern_path(pattern)

    assert_select "table.tiling__modes tbody tr", Tiling::MODES.size
    assert_select "table.tiling__modes tbody tr.tiling--refused td", text: "Doesn't tile"
    assert_select "form[action=?] button", pattern_tiling_path(pattern), text: /Snap to 26\.565°/
  end

  test "a pattern that already closes is offered no snap" do
    pattern = Pattern.create!(name: "Fitted", slot_count: 2, angle: 45)

    get pattern_path(pattern)

    assert_select "tr.tiling--refused", 0
    assert_select "form[action=?]", pattern_tiling_path(pattern), 0
  end

  test "snapping moves the angle to one that closes" do
    pattern = Pattern.create!(name: "Snapped", slot_count: 2, angle: 30)

    patch pattern_tiling_path(pattern)

    assert_redirected_to pattern_path(pattern)
    assert_in_delta 26.565, pattern.reload.angle.to_f, 0.001
    assert_predicate Tiling.new(pattern, mode: :unbroken), :seamless?
  end

  test "snapping a pattern that already closes leaves it alone" do
    pattern = Pattern.create!(name: "Already", slot_count: 2, angle: 45)

    patch pattern_tiling_path(pattern)

    assert_in_delta 45, pattern.reload.angle.to_f, 0.001
  end

  test "an angle off the axes composes and draws" do
    post patterns_path, params: { pattern: { name: "Diagonal", slot_count: 2, angle: 22.5 } }

    pattern = Pattern.order(:created_at).last

    assert_in_delta 22.5, pattern.angle.to_f, 0.001

    get pattern_path(pattern)

    assert_select "svg pattern[patternTransform=?]", "rotate(67.5)"
  end

  test "composing a pattern goes to it" do
    assert_difference "Pattern.count", 1 do
      post patterns_path, params: { pattern: { name: "Ticking", slot_count: 4, angle: 90 } }
    end

    pattern = Pattern.order(:created_at).last

    assert_redirected_to pattern_path(pattern)
    assert_equal 4, pattern.values.count
    assert_equal 4, pattern.sequence.stripes.count
  end

  test "a pattern with no name is refused and says why" do
    assert_no_difference "Pattern.count" do
      post patterns_path, params: { pattern: { name: "", slot_count: 2 } }
    end

    assert_response :unprocessable_content
    assert_select ".errors"
  end

  test "renaming a pattern keeps its structure" do
    pattern = Pattern.create!(name: "Old", slot_count: 3)

    patch pattern_path(pattern), params: { pattern: { name: "New", angle: 0 } }

    assert_redirected_to pattern_path(pattern)
    assert_equal "New", pattern.reload.name
    assert_equal 0, pattern.angle
    assert_equal 3, pattern.values.count
  end

  test "a pattern can be taken away" do
    pattern = Pattern.create!(name: "Doomed", slot_count: 2)

    assert_difference "Pattern.count", -1 do
      delete pattern_path(pattern)
    end

    assert_redirected_to patterns_path
  end

  test "slot count is not editable after composing, because + and - are the way" do
    pattern = Pattern.create!(name: "Fixed", slot_count: 2)

    patch pattern_path(pattern), params: { pattern: { name: "Fixed", slot_count: 5 } }

    assert_equal 2, pattern.reload.slot_count
  end
end
