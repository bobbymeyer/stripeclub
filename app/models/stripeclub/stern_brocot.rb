# The nearest rational to a slope, with both parts kept small.
#
# Snap To Tiling needs this: an unbroken axis-aligned tile only closes on
# itself when the stripe direction has a rational slope against the tile, and
# the smaller the two integers the fewer stripes the tile needs to hold. A
# slope of 0.7071 does not tile at any size worth exporting; 2/3 does.
module Stripeclub
  module SternBrocot
    module_function

    # Walk the tree of every rational there is. Each step takes the mediant of
    # the two fractions the target lies between, which is the next rational to
    # appear between them and always in lowest terms — so the walk narrows on
    # the target through the simplest fractions first and never has to reduce
    # anything.
    #
    # It stops when the next mediant would be bigger than the limit allows.
    # Every descendant of a node is larger in both parts than the node itself,
    # so once the child is too big nothing below it can be small enough, and the
    # answer is whichever of the two current bounds is nearer.
    def nearest(target, limit)
      return Rational(0, 1) if target <= 0

      low, high = [ 0, 1 ], [ 1, 0 ]

      loop do
        mediant = [ low[0] + high[0], low[1] + high[1] ]
        break if mediant[0] > limit || mediant[1] > limit

        case mediant[0].fdiv(mediant[1]) <=> target
        when 0 then return Rational(*mediant)
        when -1 then low = mediant
        else high = mediant
        end
      end

      nearer_of(low, high, target, limit)
    end

    # 1/0 is the tree's upper bound and not a number. It is dropped rather than
    # compared, which leaves the flat side — and a target steeper than the limit
    # can reach then lands on limit/1, the steepest slope small integers have.
    def nearer_of(low, high, target, limit)
      [ low, high ]
        .reject { |numerator, denominator| denominator.zero? || numerator > limit || denominator > limit }
        .map { |pair| Rational(*pair) }
        .min_by { |rational| [ (rational - target.to_r).abs, rational.denominator ] }
    end
    private_class_method :nearer_of
  end
end
