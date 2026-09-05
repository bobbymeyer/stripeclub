require "test_helper"

module Stripeclub
  class Pandatone::CatalogTest < ActiveSupport::TestCase
    # The handoff's rule: fetch once, filter locally. Filtering is a question
    # about colours that are already in hand, and asking Pandatone again for
    # every change of slot count would put a round trip behind a slider.
    test "the catalogue is fetched once however often it is filtered" do
      source = CountingSource.new(palettes)
      catalog = Pandatone::Catalog.new(source)

      catalog.serving(2)
      catalog.serving(4)
      catalog.cycling(6)

      assert_equal 1, source.fetches
    end

    # The source answers in Pandatone's wire format — what the API sends and
    # what a host with Pandatone in the same process hands over — and the
    # catalogue reads it the same way either arrives.
    test "the source answers in the wire format, with either kind of key" do
      symbols = Pandatone::Catalog.new(-> { [ { id: 1, name: "One", colors: [ { id: 9, name: "c", hex: "#123456" } ] } ] })
      strings = Pandatone::Catalog.new(-> { [ { "id" => 1, "name" => "One", "colors" => [ { "id" => 9, "name" => "c", "hex" => "#123456" } ] } ] })

      assert_equal [ "#123456" ], symbols.palettes.first.colors.map(&:hex)
      assert_equal [ "#123456" ], strings.palettes.first.colors.map(&:hex)
    end

    test "serving a pattern needs a colour for every slot" do
      catalog = Pandatone::Catalog.new(CountingSource.new(palettes))

      assert_equal [ "Two", "Three", "Six" ], catalog.serving(2).map(&:name)
      assert_equal [ "Six" ], catalog.serving(4).map(&:name)
    end

    test "cycling cleanly needs the palette to divide the stripe count" do
      catalog = Pandatone::Catalog.new(CountingSource.new(palettes))

      assert_equal [ "Two", "Three", "Six" ], catalog.cycling(6).map(&:name)
      assert_equal [ "Two" ], catalog.cycling(4).map(&:name)
      assert_equal [ "Three" ], catalog.cycling(9).map(&:name)
    end

    private
      def palettes
        [ built("Two", 2), built("Three", 3), built("Six", 6) ]
      end

      # In the wire format, as a source answers.
      def built(name, size)
        colors = Array.new(size) do |index|
          level = index * (255 / size)
          { "id" => index, "name" => "c#{index}", "hex" => "#000000", "rgb" => { "r" => level, "g" => level, "b" => level } }
        end

        { "id" => name.hash, "name" => name, "tags" => [], "colors" => colors }
      end

      class CountingSource
        attr_reader :fetches

        def initialize(palettes)
          @palettes = palettes
          @fetches = 0
        end

        def call
          @fetches += 1
          @palettes
        end
      end
  end
end
