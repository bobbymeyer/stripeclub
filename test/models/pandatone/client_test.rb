require "test_helper"

class Pandatone::ClientTest < ActiveSupport::TestCase
  setup do
    @client = Pandatone::Client.new(url: "https://pandatone.test", token: "sekrit")
  end

  test "the token goes out as a bearer credential" do
    index = stub_index([])

    @client.palettes

    assert_requested index.with(headers: {
      "Authorization" => "Bearer sekrit", "Accept" => "application/json"
    })
  end

  # Pandatone's index carries id, name and tags and no colours, and every
  # filter Stripeclub applies is a question about the colours: how many there
  # are, and how light each one is. So the colours have to be fetched a
  # palette at a time. It is a request per palette, done once, and the way out
  # of it is a change to Pandatone — a count on the summary, or an index that
  # can be asked to include colours — not a cleverer client.
  test "colours are fetched per palette, because the index does not carry them" do
    stub_index([ summary(1, "Warm"), summary(2, "Cool") ])
    warm = stub_palette(1, "Warm", "#FAF8F4", "#12120F")
    cool = stub_palette(2, "Cool", "#0000FF")

    palettes = @client.palettes

    assert_requested warm
    assert_requested cool
    assert_equal [ "Warm", "Cool" ], palettes.map(&:name)
    assert_equal [ 2, 1 ], palettes.map(&:size)
  end

  test "a palette arrives with its colours measured" do
    stub_index([ summary(1, "Warm") ])
    stub_palette(1, "Warm", "#FAF8F4", "#12120F")

    palette = @client.palettes.first

    assert_equal [ "#FAF8F4", "#12120F" ], palette.ranked.map(&:hex)
    assert_in_delta 0.98, palette.ranked.first.luminance, 0.005
  end

  # Each of these would otherwise read as "Pandatone has no palettes", and a
  # catalogue that is empty because the token is wrong is worse than one that
  # says so: every colorway would rerender against nothing.
  test "a refused token is not an empty catalogue" do
    stub_request(:get, "https://pandatone.test/api/v1/palettes")
      .to_return(status: 401, body: '{"error":"Unauthorized"}')

    assert_raises(Pandatone::Unauthorized) { @client.palettes }
  end

  test "a server that is not there is not an empty catalogue" do
    stub_request(:get, "https://pandatone.test/api/v1/palettes").to_raise(Errno::ECONNREFUSED)

    assert_raises(Pandatone::Unreachable) { @client.palettes }
  end

  test "a timeout is not an empty catalogue" do
    stub_request(:get, "https://pandatone.test/api/v1/palettes").to_timeout

    assert_raises(Pandatone::Unreachable) { @client.palettes }
  end

  test "a body that is not json is not an empty catalogue" do
    stub_request(:get, "https://pandatone.test/api/v1/palettes")
      .to_return(status: 200, body: "<html>bad gateway</html>")

    assert_raises(Pandatone::Error) { @client.palettes }
  end

  test "a client with nowhere to reach says so rather than being built" do
    assert_raises(Pandatone::Error) { Pandatone::Client.new(url: "", token: "sekrit") }
  end

  test "a base url with a path of its own is kept" do
    stub = stub_request(:get, "https://host.test/pandatone/api/v1/palettes")
      .to_return(body: "[]", headers: { "Content-Type" => "application/json" })

    Pandatone::Client.new(url: "https://host.test/pandatone", token: "t").palettes

    assert_requested stub
  end

  private
    def summary(id, name)
      { "id" => id, "name" => name, "tags" => [] }
    end

    def stub_index(summaries)
      stub_request(:get, "https://pandatone.test/api/v1/palettes")
        .to_return(body: summaries.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_palette(id, name, *hexes)
      colors = hexes.each_with_index.map do |hex, index|
        {
          "id" => (id * 100) + index, "name" => "Colour #{index}", "hex" => hex,
          "rgb" => { "r" => hex[1..2].to_i(16), "g" => hex[3..4].to_i(16), "b" => hex[5..6].to_i(16) },
          "tags" => []
        }
      end

      stub_request(:get, "https://pandatone.test/api/v1/palettes/#{id}")
        .to_return(body: summary(id, name).merge("colors" => colors).to_json,
          headers: { "Content-Type" => "application/json" })
    end
end
