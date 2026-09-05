require "test_helper"
require "nokogiri"

# A handful of whole documents, kept on disk and compared byte for byte.
#
# The other SVG tests each ask one question and would all still pass if the
# document around the answer changed — an attribute dropped, a wrapper added,
# numbers formatted differently. These say what the file looks like, so a
# change to it has to be a change someone made on purpose.
#
# Regenerate with GOLDEN=overwrite, and read the diff before committing it.
module Stripeclub
  class SvgGoldenTest < ActiveSupport::TestCase
    FIXTURES = Stripeclub::Engine.root.join("test/fixtures/files/svg")

    CASES = {
      "vertical-quarters" => { angle: 90, widths: [ 0.25, 0.25, 0.25, 0.25 ] },
      "vertical-uneven" => { angle: 90, widths: [ 0.6, 0.4 ] },
      "horizontal-thirds" => { angle: 0, widths: Array.new(3) { BigDecimal("0.333333") } },
      "horizontal-ground-and-hairline" => { angle: 0, widths: [ 0.94, 0.06 ] },
      "diagonal-halves" => { angle: 45, widths: [ 0.5, 0.5 ] },
      "diagonal-leaning-back" => { angle: 116.565, widths: [ 0.7, 0.3 ] }
    }.freeze

    CASES.each do |name, attributes|
      test "#{name} renders as its golden" do
        rendered = pretty(SvgPattern.new(colorway_for(**attributes), id: name).to_s)
        golden = FIXTURES.join("#{name}.svg")

        golden.write(rendered) if ENV["GOLDEN"] == "overwrite" || !golden.exist?

        assert_equal golden.read, rendered, "#{name}.svg has moved. GOLDEN=overwrite to accept it."
      end
    end

    private
      def pretty(svg)
        Nokogiri::XML(svg, &:noblanks).to_xml(indent: 2)
      end

      def colorway_for(angle:, widths:)
        pattern = Pattern.create!(name: "Golden", slot_count: widths.size, angle: angle)

        pattern.sequence.stripes.each_with_index do |stripe, index|
          stripe.update_column(:width, widths[index])
        end
        pattern.sequence.stripes.reload

        Colorway.create!(pattern: pattern, palette: pandatone_palette(*grays(widths.size)))
      end

      def grays(count)
        step = 255 / [ count - 1, 1 ].max

        Array.new(count) { |index| format("#%02X%02X%02X", *([ 255 - (index * step) ] * 3)) }
      end
  end
end
