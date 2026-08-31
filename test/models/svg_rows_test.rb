require "test_helper"
require "nokogiri"

class SvgRowsTest < ActiveSupport::TestCase
  # With rows the tile stops being one turned square and becomes an
  # axis-aligned block of bands, each filled by a pattern of its own carrying
  # its own turn. That is what makes the four transforms expressible at all: a
  # single patternTransform applies to everything, so no row under it could
  # lean the other way or run at a different scale.
  test "each row gets a pattern of its own and the tile is a block of bands" do
    document = render(rows: 3)

    assert_equal 4, document.css("defs pattern").size
    assert_equal 3, document.css("defs pattern[id*=row]").size
    assert_equal 3, document.at_css("pattern:not([id*=row])").css("rect").size
  end

  test "a band is filled by its own row's pattern" do
    document = render(rows: 2)
    tile = document.at_css("pattern:not([id*=row])")

    assert_equal [ "url(#banded-row-0)", "url(#banded-row-1)" ], tile.css("rect").map { |r| r["fill"] }
  end

  test "the bands take their heights from the rows and close on the tile" do
    document = render(rows: 4, period: 100, depth: 1)
    bands = document.at_css("pattern:not([id*=row])").css("rect")

    assert_equal [ "0", "25", "50", "75" ], bands.map { |band| band["y"] }
    assert_equal 100.0, bands.last["y"].to_f + bands.last["height"].to_f
  end

  test "the block is as deep as the pattern says, measured in repeats" do
    tile = render(rows: 2, period: 60, depth: 2).at_css("pattern:not([id*=row])")

    assert_equal "120", tile["height"]
  end

  # A phase is a shift along the normal, which is what a pattern's own x is
  # once the turn has been applied to it — so it needs no rects moved and none
  # split at the wrap.
  test "a phase shift is the row pattern's own offset" do
    document = render(rows: 2, period: 80) { |rows| rows.second.update!(phase: 0.5) }

    assert_equal "0", document.at_css("#banded-row-0")["x"]
    assert_equal "40", document.at_css("#banded-row-1")["x"]
  end

  test "a mirrored row turns the other way" do
    document = render(rows: 2, angle: 30) { |rows| rows.second.update!(mirrored: true) }

    assert_equal "rotate(60)", document.at_css("#banded-row-0")["patternTransform"]
    assert_equal "rotate(-60)", document.at_css("#banded-row-1")["patternTransform"]
  end

  test "a width scale makes the row's repeat wider or finer" do
    document = render(rows: 2, period: 60) { |rows| rows.second.update!(width_numerator: 1, width_denominator: 3) }

    assert_equal "60", document.at_css("#banded-row-0")["width"]
    assert_equal "20", document.at_css("#banded-row-1")["width"]
  end

  # The tile has to be a whole number of every row's horizontal period or the
  # rows seam where it wraps — and the reference form is not allowed to seam.
  test "the tile is a whole number of every row's repeat" do
    document = render(rows: 2, period: 60, angle: 90) do |rows|
      rows.second.update!(width_numerator: 2, width_denominator: 1)
    end

    width = document.at_css("pattern:not([id*=row])")["width"].to_f

    assert_equal 120.0, width
    assert_equal 0, width % 60
    assert_equal 0, width % 120
  end

  # Horizontal period = P / sin θ, which is the number Tiling reports for the
  # row-broken mode. The two have to be the same number or one of them is
  # describing a tile nobody renders.
  test "a turned tile is as wide as the horizontal period Tiling reports" do
    pattern = banded(rows: 1, angle: 30)
    document = parse(SvgPattern.new(ValueScale.new(pattern), period: 60, id: "banded").to_s)

    expected = Tiling.new(pattern, mode: :row_broken).horizontal_period(60)

    assert_in_delta expected, document.at_css("pattern:not([id*=row])")["width"].to_f, 0.01
    assert_in_delta 120.0, expected, 0.01
  end

  test "a colour offset moves a row along the palette" do
    pattern = banded(rows: 2, angle: 90, slot_count: 4)
    colorway = Colorway.create!(pattern: pattern,
      palette: pandatone_palette("#FFFFFF", "#DDDDDD", "#999999", "#000000"))
    pattern.rows.second.update!(color_offset: 1)

    document = parse(SvgPattern.new(colorway.reload, period: 60, id: "banded").to_s)

    plain = document.at_css("#banded-row-0").css("rect").map { |r| r["fill"] }
    moved = document.at_css("#banded-row-1").css("rect").map { |r| r["fill"] }

    assert_equal %w[ #FFFFFF #DDDDDD #999999 #000000 ], plain
    assert_equal plain.rotate(1), moved
  end

  test "a pattern with no rows still renders as one turned tile" do
    pattern = Pattern.create!(name: "Plain #{rand(1 << 20)}", slot_count: 2, angle: 45)
    document = parse(SvgPattern.new(ValueScale.new(pattern), id: "plain").to_s)

    assert_equal 1, document.css("defs pattern").size
    assert_equal "rotate(45)", document.at_css("pattern")["patternTransform"]
  end

  private
    def banded(rows:, angle: 90, slot_count: 2, depth: 1)
      Pattern.create!(name: "Banded #{rand(1 << 30)}", slot_count: slot_count, angle: angle, row_depth: depth)
        .divide_into_rows!(rows)
    end

    def render(rows:, angle: 90, period: 60, depth: 1)
      pattern = banded(rows: rows, angle: angle, depth: depth)
      yield pattern.rows if block_given?

      parse(SvgPattern.new(ValueScale.new(pattern.reload), period: period, id: "banded").to_s)
    end

    def parse(svg)
      Nokogiri::XML(svg).tap(&:remove_namespaces!)
    end
end
