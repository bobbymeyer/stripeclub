require "test_helper"
require "nokogiri"

# One whole document per rule, kept on disk.
#
# The palette is deliberately stored out of rank order — red, cream, ink, gold
# ranks as cream, gold, red, ink — so every fixture here would be wrong in a
# visible way if a rule read the wrong one of the two orders. That is the
# mistake these are for: only Auto-Value-Match reads the rank, and the other
# three read the position, and both are lists of four colours.
#
# Regenerate with GOLDEN=overwrite, and read the diff before committing it.
module Stripeclub
  class ColorwayGoldenTest < ActiveSupport::TestCase
    FIXTURES = Stripeclub::Engine.root.join("test/fixtures/files/svg")

    PALETTE = %w[ #C1272D #FAF8F4 #12120F #E3B505 ].freeze

    CASES = {
      "rule-auto-value-match" => ->(colorway) { colorway },
      "rule-assigned-slot" => lambda { |colorway|
        { 0 => 2, 1 => 0, 2 => 3, 3 => 1 }.each do |position, slot|
          colorway.bind(value(colorway, position), kind: :assigned_slot, slot: slot)
        end
        colorway
      },
      "rule-increment" => lambda { |colorway|
        colorway.pattern.values.each { |v| colorway.bind(v, kind: :increment, start: 0, step: 1) }
        colorway
      },
      "rule-random" => lambda { |colorway|
        colorway.pattern.values.each { |v| colorway.bind(v, kind: :random, subset: [ 0, 3 ], seed: 7) }
        colorway
      }
    }.freeze

    def self.value(colorway, position)
      colorway.pattern.values.find_by!(position: position)
    end

    CASES.each do |name, prepare|
      test "#{name} renders as its golden" do
        colorway = prepare.call(dressed)
        rendered = pretty(SvgPattern.new(colorway.reload, id: name).to_s)
        golden = FIXTURES.join("#{name}.svg")

        golden.write(rendered) if ENV["GOLDEN"] == "overwrite" || !golden.exist?

        assert_equal golden.read, rendered, "#{name}.svg has moved. GOLDEN=overwrite to accept it."
      end
    end

    test "the palette is stored out of its rank order, or these fixtures prove nothing" do
      ranked = pandatone_palette(*PALETTE).ranked.map(&:hex)

      assert_equal %w[ #FAF8F4 #E3B505 #C1272D #12120F ], ranked
      assert_not_equal PALETTE, ranked
    end

    private
      def dressed
        pattern = Pattern.create!(name: "Golden colorway #{rand(1 << 20)}", slot_count: 4, angle: 90)

        Colorway.create!(pattern: pattern, palette: pandatone_palette(*PALETTE))
      end

      def pretty(svg)
        Nokogiri::XML(svg, &:noblanks).to_xml(indent: 2)
      end
  end
end
