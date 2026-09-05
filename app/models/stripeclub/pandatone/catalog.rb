# Every palette Pandatone has, fetched once and then filtered here.
#
# Filtering is a question about colours already in hand — how many there are,
# and whether that number divides a stripe count — and putting a round trip
# behind a slot-count slider would make the answer arrive after the next
# question. One fetch, and the filters are array work.
#
# Where the palettes come from is Stripeclub.palette_source: over HTTP from
# a Pandatone somewhere else, or straight from one in the same process. The
# catalogue reads the wire format either way.
module Stripeclub
  module Pandatone
    class Catalog
      # How long a fetched catalogue stands before it is asked for again.
      #
      # Held in the process rather than in Rails.cache: it is a handful of value
      # objects for one person's tool, the development cache store is a null store
      # unless someone has turned it on, and a catalogue that silently did nothing
      # would look exactly like one that worked. Another process fetches its own,
      # which costs one round of requests and cannot go stale differently.
      CACHE_FOR = 5.minutes

      class << self
        def current(source = Stripeclub.palette_source)
          forget! if @fetched_at.nil? || @fetched_at < CACHE_FOR.ago

          @current ||= new(source).tap { @fetched_at = Time.current }
        end

        # What "refresh from Pandatone" does, and what a colorway checking itself
        # for drift wants first.
        def forget!
          @current = @fetched_at = nil
        end
      end

      def self.fetch(source = Stripeclub.palette_source)
        new(source)
      end

      def initialize(source)
        @source = source
      end

      def palettes
        @palettes ||= Array(@source.call).map { |json| Palette.from_json(json.deep_stringify_keys) }
      end

      # Auto-Value-Match: p >= n.
      def serving(slot_count)
        palettes.select { |palette| palette.serves?(slot_count) }
      end

      # Increment: p divides the stripe count.
      def cycling(stripe_count)
        palettes.select { |palette| palette.cycles_cleanly?(stripe_count) }
      end
    end
  end
end
