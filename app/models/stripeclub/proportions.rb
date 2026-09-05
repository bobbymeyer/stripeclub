# Parts of a whole, stored to a fixed number of places, that have to sum to
# one.
#
# It is the sequence's rule about stripe widths, and now the rows' rule about
# heights as well. Said once here rather than twice, because the interesting
# part is not the sum — it is how much rounding the storage forces, and two
# copies of that number would eventually disagree.
module Stripeclub
  module Proportions
    # Places a proportion is stored to.
    SCALE = 6

    module_function

    def total(parts)
      parts.sum { |part| part&.to_d || 0 }
    end

    # Half a unit in the last stored place, per part: the most that rounding to
    # SCALE places can cost and no more.
    #
    # A third cannot be written in six places, so three of them come to 0.999999
    # — a fixed epsilon would have to be loose enough to admit that, and would
    # then also admit a whole that is genuinely short.
    def slack(count)
      count * (BigDecimal(1) / 10**SCALE) / 2
    end

    def sum_to_one?(parts)
      (total(parts) - 1).abs <= slack(parts.size)
    end

    # One divided `count` ways, summing to one exactly. Even division of a
    # number that does not divide leaves a remainder, and a remainder has to
    # land somewhere: it lands on the last part, because that is the only place
    # it can go without making the first one the odd size.
    def even(count)
      each = (BigDecimal(1) / count).floor(SCALE)

      Array.new(count, each).tap { |parts| parts[-1] += 1 - parts.sum }
    end

    # Where each part begins, and where the last one ends — with the end placed
    # at one rather than accumulated to it.
    #
    # Parts stored to six places can sum to 0.999999 and be as close to one as
    # six places allow. Multiplied out, that difference is a hairline of
    # whatever sits behind the pattern showing through every repeat, which is
    # the one thing a repeat may not do.
    def edges(parts)
      running = BigDecimal(0)

      parts.map { |part| running.tap { running += part.to_d } } << BigDecimal(1)
    end

    # The same parts in the same proportion to each other, scaled back onto one.
    def normalized(parts)
      whole = total(parts)
      return parts if whole.zero?

      scaled = parts.map { |part| (part.to_d / whole).floor(SCALE) }

      scaled.tap { |all| all[-1] += 1 - all.sum }
    end
  end
end
