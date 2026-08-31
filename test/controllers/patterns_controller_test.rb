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
    assert_select "table.table tbody tr", 3
    assert_select "dl.pairs"
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
