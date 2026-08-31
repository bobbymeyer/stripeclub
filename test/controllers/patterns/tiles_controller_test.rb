require "test_helper"
require "nokogiri"

class Patterns::TilesControllerTest < ActionDispatch::IntegrationTest
  test "a tile comes back as one tile, not a picture of several" do
    pattern = Pattern.create!(name: "Bias", slot_count: 2, angle: 30)
    tile = Tile.new(ValueScale.new(pattern), period: 60)

    get pattern_tile_path(pattern, format: :svg)

    assert_response :success
    assert_equal "image/svg+xml", response.media_type

    document = Nokogiri::XML(response.body).tap(&:remove_namespaces!)

    assert_in_delta tile.width, document.root["width"].to_f, 0.01
    assert_in_delta tile.height, document.root["height"].to_f, 0.01
  end

  # The file says whether it closes, because it is going to be opened
  # somewhere that is not this page.
  test "the tile says what it is and whether it closes" do
    pattern = Pattern.create!(name: "Bias", slot_count: 2, angle: 30)

    get pattern_tile_path(pattern, format: :svg)

    document = Nokogiri::XML(response.body).tap(&:remove_namespaces!)

    assert_equal "Bias", document.at_css("title").text
    assert_match(/tan 30°/, document.at_css("desc").text)
  end

  test "a png comes back as a png of the size the scale asks for" do
    pattern = Pattern.create!(name: "Upright", slot_count: 2, angle: 90)

    get pattern_tile_path(pattern, format: :png, params: { scale: 2 })

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal "\x89PNG".b, response.body[0, 4].b

    image = ChunkyPNG::Image.from_blob(response.body)

    assert_equal 120, image.width
    assert_equal 120, image.height
  end

  test "a dressed tile takes its colours from the colorway" do
    pattern = Pattern.create!(name: "Dressed", slot_count: 2, angle: 90)
    colorway = Colorway.create!(pattern: pattern, palette: pandatone_palette("#FF0000", "#0000FF"))

    get pattern_tile_path(pattern, format: :svg, params: { colorway: colorway.id })

    assert_includes response.body, "#FF0000"
    assert_includes response.body, "#0000FF"
  end

  test "an undressed tile is drawn in value" do
    pattern = Pattern.create!(name: "Undressed", slot_count: 2, angle: 90)

    get pattern_tile_path(pattern, format: :svg)

    assert_includes response.body, "#F8F8F8"
  end

  # Nothing honest to write into the file.
  test "a colorway that cannot dress the pattern gives no tile" do
    pattern = Pattern.create!(name: "Outgrown", slot_count: 2, angle: 90)
    colorway = Colorway.create!(pattern: pattern, palette: pandatone_palette("#FF0000", "#0000FF"))
    pattern.add_value!

    get pattern_tile_path(pattern, format: :svg, params: { colorway: colorway.id })

    assert_response :unprocessable_content
  end

  test "a rowed tile carries its whole block" do
    pattern = Pattern.create!(name: "Banded", slot_count: 2, angle: 45, row_depth: 2).divide_into_rows!(4)

    get pattern_tile_path(pattern, format: :svg)

    document = Nokogiri::XML(response.body).tap(&:remove_namespaces!)

    assert_equal 5, document.css("defs pattern").size
    assert_in_delta 120, document.root["height"].to_f, 0.01
  end
end
