require "test_helper"

module Stripeclub
  class ImperfectionTest < ActiveSupport::TestCase
    test "a pattern is clean until it is roughened" do
      pattern = Pattern.create!(name: "Clean #{rand(1 << 20)}", slot_count: 3)

      assert_nil pattern.imperfection
      assert_equal pattern.sequence.stripes.map(&:width), pattern.drawn_widths
    end

    test "an imperfection that does nothing is not an imperfection" do
      assert_not roughened.any?
    end

    # The design constraint the whole of round two turns on: the composition
    # stays what someone typed, and the roughening is applied when it is drawn.
    test "variance leaves the stored widths alone" do
      pattern = varied(0.4)
      stored = pattern.sequence.stripes.map { |stripe| stripe.width.to_f }

      assert_not_equal stored, pattern.drawn_widths.map(&:to_f)
      assert_equal stored, pattern.reload.sequence.stripes.map { |stripe| stripe.width.to_f }
    end

    test "turning variance off gives the clean pattern back" do
      pattern = varied(0.4)
      clean = pattern.sequence.stripes.map(&:width)

      pattern.imperfection.update!(variance: 0)

      assert_equal clean, pattern.reload.drawn_widths
    end

    # The rule the handoff states: jittered, and the sequence still sums to one.
    # Without that a repeat stops being a repeat and every other piece of
    # arithmetic here stops being true.
    test "jittered widths still sum to one" do
      [ 0.05, 0.2, 0.5, 0.9 ].each do |variance|
        pattern = varied(variance, slot_count: 5)

        assert_equal 1, Proportions.total(pattern.drawn_widths), "#{variance} did not come back to one"
        assert Proportions.sum_to_one?(pattern.drawn_widths)
      end
    end

    test "no stripe is jittered out of existence" do
      pattern = varied(Imperfection::MOST_VARIANCE, slot_count: 6)

      assert(pattern.drawn_widths.all?(&:positive?), "a stripe was jittered to nothing")
    end

    test "a variance that could take a stripe to nothing is refused" do
      assert_predicate roughened(variance: 1.0), :invalid?
      assert_predicate roughened(variance: -0.1), :invalid?
      assert_predicate roughened(variance: Imperfection::MOST_VARIANCE), :valid?
    end

    # Imperfection that came out differently on every render would not be a
    # pattern at all.
    test "the same seed draws the same imperfection" do
      pattern = varied(0.3, slot_count: 4)

      assert_equal pattern.drawn_widths, Pattern.find(pattern.id).drawn_widths
    end

    test "another seed draws another imperfection" do
      pattern = varied(0.3, slot_count: 4)
      first = pattern.drawn_widths

      pattern.imperfection.update!(seed: pattern.imperfection.seed + 1)

      assert_not_equal first, pattern.reload.drawn_widths
    end

    test "an imperfection seeds itself rather than drawing differently each time" do
      assert_kind_of Integer, roughened(variance: 0.2).tap(&:save!).seed
    end

    # Only the geometry can be sampled: a displacement map and a noise multiply
    # are things a renderer does to a picture.
    test "an imperfection knows whether a raster can carry all of it" do
      assert roughened(variance: 0.2).only_geometry?
      assert_not roughened(variance: 0.2, wobble: 0.1).only_geometry?
      assert_not roughened(texture: 0.3).only_geometry?
    end

    test "imperfection goes when the pattern does" do
      pattern = varied(0.2)

      assert_difference "Imperfection.count", -1 do
        pattern.destroy
      end
    end

    private
      def roughened(**attributes)
        Imperfection.new(pattern: Pattern.create!(name: "Rough #{rand(1 << 30)}", slot_count: 2), **attributes)
      end

      def varied(variance, slot_count: 3)
        pattern = Pattern.create!(name: "Varied #{rand(1 << 30)}", slot_count: slot_count)
        Imperfection.create!(pattern: pattern, variance: variance, seed: 4242)

        pattern.reload
      end
  end
end
