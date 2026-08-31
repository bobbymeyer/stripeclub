# Every palette Pandatone has, fetched once and then filtered here.
#
# Filtering is a question about colours already in hand — how many there are,
# and whether that number divides a stripe count — and putting a round trip
# behind a slot-count slider would make the answer arrive after the next
# question. One fetch, and the filters are array work.
class Pandatone::Catalog
  def self.fetch(client = Pandatone::Client.configured)
    new(client)
  end

  def initialize(client)
    @client = client
  end

  def palettes
    @palettes ||= @client.palettes
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
