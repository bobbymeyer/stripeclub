require "test_helper"

class SternBrocotTest < ActiveSupport::TestCase
  test "a rational already small enough is itself" do
    assert_equal Rational(1, 1), SternBrocot.nearest(1.0, 4)
    assert_equal Rational(1, 2), SternBrocot.nearest(0.5, 4)
    assert_equal Rational(3, 4), SternBrocot.nearest(0.75, 4)
  end

  # 0.7 sits between 2/3 and 3/4. It is nearer 2/3 by 0.017, and a walk that
  # stopped at the first fraction inside a tolerance rather than the nearest
  # one would answer 3/4.
  test "a slope between two rationals goes to the nearer" do
    assert_equal Rational(2, 3), SternBrocot.nearest(0.7, 4)
  end

  test "a flat slope is zero and a steep one is capped" do
    assert_equal Rational(0, 1), SternBrocot.nearest(0.0, 4)
    assert_equal Rational(4, 1), SternBrocot.nearest(37.5, 4)
  end

  test "nothing comes back larger than the limit allows" do
    (1..60).each do |step|
      slope = step / 7.0
      answer = SternBrocot.nearest(slope, 4)

      assert_operator answer.denominator, :<=, 4, "#{slope} gave #{answer}"
      assert_operator answer.numerator, :<=, 4, "#{slope} gave #{answer}"
    end
  end

  test "a tighter limit gives a coarser answer" do
    assert_equal Rational(1, 3), SternBrocot.nearest(0.34, 4)
    assert_equal Rational(1, 2), SternBrocot.nearest(0.34, 2)
  end

  # The walk is an optimisation over asking every candidate. With a limit of
  # four there are few enough candidates to ask all of them, so the test does
  # exactly that and the two have to agree — which is a stronger statement
  # about the walk than any hand-picked pair of slopes.
  test "the walk agrees with asking every rational there is" do
    (0..400).each do |thousandths|
      slope = thousandths / 100.0

      assert_equal exhaustive_nearest(slope, 4), SternBrocot.nearest(slope, 4),
        "the walk and the search disagree at #{slope}"
    end
  end

  private
    def exhaustive_nearest(target, limit)
      candidates = (0..limit).to_a.product((1..limit).to_a)
        .map { |numerator, denominator| Rational(numerator, denominator) }
        .select { |rational| rational.numerator <= limit && rational.denominator <= limit }
        .uniq

      candidates.min_by { |rational| [ (rational - target.to_r).abs, rational.denominator ] }
    end
end
