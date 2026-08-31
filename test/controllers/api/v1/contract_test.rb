require "test_helper"

# The whole of v1, snapshotted. Every shape a consumer can receive is written
# out here longhand — the payloads, the parameters that change them, and the
# error envelopes — so that a change to any of them fails in the one file
# whose job is to notice. Treat a failure here as a version bump rather than
# a fix.
#
# Behaviour lives in the controller tests beside this one. What this file pins
# is the wire format: keys, their order, and their types.
class Api::V1::ContractTest < ActionDispatch::IntegrationTest
  setup do
    @pattern = Pattern.create!(name: "Bias", slot_count: 3, angle: 30)
    @pattern.sequence.stripes.each_with_index { |s, i| s.update_column(:width, [ 0.5, 0.3, 0.2 ][i]) }

    @banded = Pattern.create!(name: "Lightning", slot_count: 2, angle: 45, row_depth: 4).divide_into_rows!(2)
    @banded.rows.second.update!(phase: 0.5, color_offset: 1, mirrored: true,
      width_numerator: 1, width_denominator: 2)

    @colorway = Colorway.create!(pattern: @pattern, palette: pandatone_palette("#C1272D", "#FAF8F4", "#12120F"))
    @colorway.bind(@pattern.values.second, kind: :assigned_slot, slot: 0)
  end

  test "the patterns index returns exactly this shape" do
    get api_v1_patterns_url

    assert_response :success
    assert_equal "application/json", response.media_type

    expected = [
      { "id" => @pattern.id, "name" => "Bias", "slot_count" => 3, "angle" => 30.0 },
      { "id" => @banded.id, "name" => "Lightning", "slot_count" => 2, "angle" => 45.0 }
    ]

    assert_equal expected, JSON.parse(response.body)
  end

  test "a pattern returns exactly this shape" do
    get api_v1_pattern_url(@pattern)

    assert_equal({
      "id" => @pattern.id, "name" => "Bias", "slot_count" => 3, "angle" => 30.0,
      "row_depth" => 1.0,
      "sequence" => [
        { "position" => 0, "value" => 0, "width" => 0.5 },
        { "position" => 1, "value" => 1, "width" => 0.3 },
        { "position" => 2, "value" => 2, "width" => 0.2 }
      ],
      "rows" => [],
      "colorways" => [
        {
          "id" => @colorway.id, "pattern_id" => @pattern.id, "palette_id" => 7,
          "palette_name" => "Sample", "invalidated" => false
        }
      ]
    }, JSON.parse(response.body))
  end

  test "a pattern with rows returns exactly this shape for them" do
    get api_v1_pattern_url(@banded)

    assert_equal [
      {
        "position" => 0, "height" => 0.5, "phase" => 0.0, "color_offset" => 0,
        "mirrored" => false, "width_scale" => [ 1, 1 ]
      },
      {
        "position" => 1, "height" => 0.5, "phase" => 0.5, "color_offset" => 1,
        "mirrored" => true, "width_scale" => [ 1, 2 ]
      }
    ], JSON.parse(response.body)["rows"]
  end

  test "a colorway returns exactly this shape" do
    get api_v1_colorway_url(@colorway)

    body = JSON.parse(response.body)

    assert_equal({
      "id" => @colorway.id, "pattern_id" => @pattern.id, "palette_id" => 7,
      "palette_name" => "Sample", "invalidated" => false,
      "taken_at" => @colorway.snapshot.taken_at.iso8601,
      "rules" => [
        { "value" => 0, "kind" => "auto_value_match", "settings" => {} },
        { "value" => 1, "kind" => "assigned_slot", "settings" => { "slot" => 0 } },
        { "value" => 2, "kind" => "auto_value_match", "settings" => {} }
      ],
      "colors" => [ "#FAF8F4", "#C1272D", "#12120F" ]
    }, body)
  end

  test "a tile returns exactly this shape" do
    get tile_api_v1_pattern_url(@pattern)

    assert_equal({
      "width" => 120.0, "height" => 69.282,
      "tiles" => true,
      "note" => "tan 30° is 1/1 against this tile, which holds 2 repeats across."
    }, JSON.parse(response.body))
  end

  test "the error envelopes are exactly these" do
    get api_v1_pattern_url("nothing-by-that-name")

    assert_response :not_found
    assert_equal({ "error" => "Not found" }, JSON.parse(response.body))

    with_token("sekrit") do
      get api_v1_patterns_url, headers: { "Authorization" => "Bearer wrong" }

      assert_response :unauthorized
      assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
    end
  end

  test "a colorway that cannot dress its pattern says so rather than drawing" do
    @pattern.add_value!

    get api_v1_colorway_url(@colorway, format: :svg)

    assert_response :unprocessable_content
    assert_equal({
      "error" => "This colorway cannot dress its pattern",
      "slot_count" => 4, "palette_size" => 3
    }, JSON.parse(response.body))
  end

  private
    def with_token(token)
      was = Rails.application.config.x.api.token
      Rails.application.config.x.api.token = token
      yield
    ensure
      Rails.application.config.x.api.token = was
    end
end
