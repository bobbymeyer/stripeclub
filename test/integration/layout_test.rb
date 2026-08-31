require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  setup { @pattern = Pattern.create!(name: "Awning", slot_count: 2) }

  test "pages render through the library's shell" do
    get patterns_path

    assert_select "a.skip-link", text: "Skip to content"
    assert_select "header.masthead .masthead__mark"
    assert_select "main#main.page"
  end

  # The finding this test exists for: the shell writes the library's six
  # stylesheet links and nothing else, so an application's own theme file —
  # the one the installer wrote, holding the accent and the grid — is linked
  # by the application or not at all. Every consumer has to remember this.
  test "the application's stylesheets are linked beside the library's" do
    get patterns_path

    hrefs = css_select("link[rel=stylesheet]").map { |link| link["href"] }

    assert hrefs.any? { |href| href.include?("its_swiss/tokens") }, "the library's own links are missing"
    assert hrefs.any? { |href| href.include?("theme") }, "theme.css holds the accent and the grid"
    assert hrefs.any? { |href| href.include?("stripeclub") }, "the domain components are missing"
  end

  test "the masthead marks the destination you are at" do
    get patterns_path

    assert_select "nav.nav a[aria-current=?]", "page", text: "Patterns"
  end

  test "a page titles itself and the application names the rest" do
    get patterns_path
    assert_select "title", text: /Patterns/

    get pattern_path(@pattern)
    assert_select "title", text: /Awning/
  end

  # The guard that would have caught it. A partial whose documentation comment
  # contains an ERB example ends the comment at the example's own `%>` and
  # emits the rest as page text — which is what its-swiss's pagination partial
  # does, and what nothing in its suite looked for, because every assertion
  # was about markup that was present rather than text that should not be.
  test "no page leaks raw template text" do
    (PatternsController::PER_PAGE + 1).times { |n| Pattern.create!(name: "Filler #{n}", slot_count: 2) }

    [ patterns_path, pattern_path(@pattern), new_pattern_path ].each do |path|
      get path

      assert_no_match(/%>/, response.body, "#{path} is emitting template source")
      assert_no_match(/<%/, response.body, "#{path} is emitting template source")
    end
  end

  test "the view transition opt-in is written once, by the shell" do
    get patterns_path

    assert_select "meta[name=view-transition][content=same-origin]", 1
  end
end
