require "test_helper"

module Stripeclub
  # The door is the host's. What the engine promises is that every endpoint
  # stands behind it: each inherits from the host's API controller, so
  # whatever that controller refuses, the engine refuses too. The dummy host
  # under test/ opens to one token; a real one looks tokens up.
  class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
    setup do
      @pattern = Pattern.create!(name: "Awning", slot_count: 2)
      @colorway = Colorway.create!(pattern: @pattern, palette: pandatone_palette("#C1272D", "#FAF8F4"))
      sign_out_client
    end

    test "closes every endpoint" do
      [ api_v1_patterns_url, api_v1_pattern_url(@pattern), tile_api_v1_pattern_url(@pattern),
        api_v1_colorways_url, api_v1_colorway_url(@colorway), tile_api_v1_colorway_url(@colorway) ].each do |url|
        get url

        assert_response :unauthorized, "#{url} answered without a token"
        assert_equal({ "error" => "Unauthorized" }, json)
      end
    end

    # A session cookie is not a token. Letting one in would mean any page on
    # the internet could drive the API from a signed-in browser.
    test "does not accept the browser session in place of a token" do
      get api_v1_patterns_url

      assert_response :unauthorized
    end

    test "the host's token opens it" do
      sign_in_client

      get api_v1_patterns_url

      assert_response :success
    end

    # A tool has to be able to read the door before it has a key.
    test "the API's description of itself is not behind the token" do
      get api_v1_openapi_url

      assert_response :success
      assert_equal "3.1.0", json["openapi"]
    end
  end
end
