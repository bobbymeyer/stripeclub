require "test_helper"

class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
  setup { Pattern.create!(name: "Awning", slot_count: 2) }

  # Stripeclub has no accounts — it is one person's tool. Unset, the API is
  # open, which is what a tool on someone's own machine wants and how the camo
  # project reaches it.
  test "with no token configured the api is open" do
    with_token(nil) { get api_v1_patterns_url }

    assert_response :success
  end

  test "with a token configured the api wants it" do
    with_token("sekrit") do
      get api_v1_patterns_url

      assert_response :unauthorized

      get api_v1_patterns_url, headers: { "Authorization" => "Bearer sekrit" }

      assert_response :success
    end
  end

  # Rails reads both spellings, so a client sending the older form is not
  # turned away for a reason nobody could guess from a 401.
  test "either spelling of the header is read" do
    with_token("sekrit") do
      get api_v1_patterns_url, headers: { "Authorization" => 'Token token="sekrit"' }

      assert_response :success
    end
  end

  test "a wrong token is refused" do
    with_token("sekrit") do
      get api_v1_patterns_url, headers: { "Authorization" => "Bearer nearly" }

      assert_response :unauthorized
    end
  end

  # A design tool put on the internet with its API open is not a decision
  # anyone makes on purpose. Failing shut with a legible reason beats both
  # guessing and a stack trace.
  test "in production with no token configured the api is shut" do
    in_production do
      with_token(nil) do
        get api_v1_patterns_url

        assert_response :unauthorized
        assert_equal "No API token is configured", JSON.parse(response.body)["error"]
      end
    end
  end

  private
    def with_token(token)
      was = Rails.application.config.x.api.token
      Rails.application.config.x.api.token = token
      yield
    ensure
      Rails.application.config.x.api.token = was
    end

    def in_production
      Rails.env = "production"
      yield
    ensure
      Rails.env = "test"
    end
end
