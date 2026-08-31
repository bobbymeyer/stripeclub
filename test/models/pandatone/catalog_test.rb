require "test_helper"

class Pandatone::CatalogTest < ActiveSupport::TestCase
  # The handoff's rule: fetch once, filter locally. Filtering is a question
  # about colours that are already in hand, and asking Pandatone again for
  # every change of slot count would put a round trip behind a slider.
  test "the catalogue is fetched once however often it is filtered" do
    client = CountingClient.new(palettes)
    catalog = Pandatone::Catalog.new(client)

    catalog.serving(2)
    catalog.serving(4)
    catalog.cycling(6)

    assert_equal 1, client.fetches
  end

  test "serving a pattern needs a colour for every slot" do
    catalog = Pandatone::Catalog.new(CountingClient.new(palettes))

    assert_equal [ "Two", "Three", "Six" ], catalog.serving(2).map(&:name)
    assert_equal [ "Six" ], catalog.serving(4).map(&:name)
  end

  test "cycling cleanly needs the palette to divide the stripe count" do
    catalog = Pandatone::Catalog.new(CountingClient.new(palettes))

    assert_equal [ "Two", "Three", "Six" ], catalog.cycling(6).map(&:name)
    assert_equal [ "Two" ], catalog.cycling(4).map(&:name)
    assert_equal [ "Three" ], catalog.cycling(9).map(&:name)
  end

  private
    def palettes
      [ built("Two", 2), built("Three", 3), built("Six", 6) ]
    end

    def built(name, size)
      colors = Array.new(size) do |index|
        level = index * (255 / size)
        Pandatone::Color.new(id: index, name: "c#{index}", hex: "#000000",
          red: level, green: level, blue: level)
      end

      Pandatone::Palette.new(id: name.hash, name: name, colors: colors)
    end

    class CountingClient
      attr_reader :fetches

      def initialize(palettes)
        @palettes = palettes
        @fetches = 0
      end

      def palettes
        @fetches += 1
        @palettes
      end
    end
end
