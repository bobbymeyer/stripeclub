# A pattern wearing a palette. The pattern is the structure and carries no
# colour; this is where colour is said, and it is said as a rule against a
# palette rather than as a list of hexes — so it survives the structure being
# edited underneath it.
#
# The palette, the snapshot, invalidation and drift are Pandatone's dresser's.
# What is this engine's is the rule per value and what a stripe resolves to.
module Stripeclub
  class Colorway < ApplicationRecord
    include Pandatone::Dresser::Colorway

    belongs_to :pattern

    # Only the values whose rule is not the default. Auto-Value-Match is what a
    # value does when nothing has been said about it, so a row for it would be
    # a row saying nothing — and "+" would have to remember to write one.
    has_many :rules, class_name: "ValueRule", dependent: :destroy, inverse_of: :colorway

    delegate :slot_count, to: :pattern

    # The colour of each stripe of the repeat, in order.
    #
    # Per stripe and not per value, because two of the four rules vary along
    # the repeat: Random draws once per stripe, and Increment counts them. A
    # value under either of those has no single colour to report.
    #
    # Empty while invalidated rather than short or padded: a colorway that
    # cannot dress every slot has nothing honest to say about any of them, and
    # the pattern is still there to be looked at underneath.
    def colors
      return [] if invalidated?

      pattern.sequence.stripes.map { |stripe| color_for(stripe) }
    end

    # `offset` is the row's colour offset, passed straight through: how far
    # along the palette this band's colours move.
    def color_for(stripe, offset: 0)
      return nil if invalidated?

      rule_for(stripe.value).color_for(stripe, offset: offset)
    end

    # The rule this value carries, or the default it carries by carrying none.
    # The default is built rather than saved: a colorway that has said nothing
    # about any of its values has no rows at all.
    def rule_for(value)
      stored_rules[value.id] ||= ValueRule.new(colorway: self, value: value, kind: :auto_value_match)
    end

    # Say what a value resolves to. One rule per value, so saying it twice
    # replaces rather than adds.
    def bind(value, kind:, **settings)
      rules.find_or_initialize_by(value: value).tap do |rule|
        rule.update!(kind: kind, settings: settings.stringify_keys)
        @stored_rules = nil
      end
    end

    # What the renderer names the `<pattern>` element, so two previews can sit
    # on one page without one filling itself from the other.
    def svg_id
      "stripeclub-colorway-#{id}"
    end

    private
      def stored_rules
        @stored_rules ||= rules.index_by(&:value_id)
      end
  end
end
