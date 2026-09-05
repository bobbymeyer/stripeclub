require "test_helper"
require "nokogiri"

module Stripeclub
  class Api::V1::PatternsControllerTest < ActionDispatch::IntegrationTest
    setup { @pattern = Pattern.create!(name: "Awning", slot_count: 2, angle: 30) }

    test "a pattern is fetchable by the name someone gave it" do
      get api_v1_pattern_url("Awning")

      assert_response :success
      assert_equal @pattern.id, JSON.parse(response.body)["id"]
    end

    test "a name that is nobody's pattern is not found rather than an error" do
      get api_v1_pattern_url("Nothing")

      assert_response :not_found
    end

    # The form to reach for unless a single tile is specifically what is wanted:
    # a pattern element, repeated by whatever renders it, seamless at any angle.
    test "a pattern comes back as the reference form" do
      get api_v1_pattern_url(@pattern, format: :svg)

      assert_response :success
      assert_equal "image/svg+xml", response.media_type

      document = Nokogiri::XML(response.body).tap(&:remove_namespaces!)

      assert_equal "Awning", document.at_css("title").text
      assert_match(/reference form/, document.at_css("desc").text)
      assert_equal "rotate(60)", document.at_css("pattern")["patternTransform"]
    end

    test "the tile comes back as one tile in either form" do
      get tile_api_v1_pattern_url(@pattern, format: :svg)

      assert_equal "image/svg+xml", response.media_type
      assert_in_delta 120, Nokogiri::XML(response.body).tap(&:remove_namespaces!).root["width"].to_f, 0.01

      get tile_api_v1_pattern_url(@pattern, format: :png)

      assert_equal "image/png", response.media_type
      assert_equal 120, ChunkyPNG::Image.from_blob(response.body).width
    end

    # How many user units a repeat is, and how many pixels a unit is worth. The
    # only two things a consumer needs that the pattern does not already say.
    test "a consumer can say how big it wants the repeat and the pixels" do
      get tile_api_v1_pattern_url(@pattern, format: :json, params: { period: 100 })

      assert_in_delta 200, JSON.parse(response.body)["width"], 0.01

      get tile_api_v1_pattern_url(@pattern, format: :png, params: { period: 100, scale: 2 })

      assert_equal 400, ChunkyPNG::Image.from_blob(response.body).width
    end

    test "a period nobody could draw is brought back to one that can be" do
      get tile_api_v1_pattern_url(@pattern, format: :json, params: { period: 100_000 })

      assert_in_delta 800, JSON.parse(response.body)["width"], 0.01
    end
  end
end
