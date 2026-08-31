# A few patterns to look at. Structure only — none of these has a palette,
# because none of them needs one to be a pattern.
#
# The two axes are laid out directly; everything else is the same repeat with
# the tile turned under it. "Bias" does not close on an unbroken tile — that is
# the point of it, and the show page says so and offers the nearest angle that
# does.
COMPOSITIONS = [
  { name: "Awning", slot_count: 2, angle: 90, widths: [ 0.6, 0.4 ] },
  { name: "Ticking", slot_count: 2, angle: 90, widths: [ 0.88, 0.12 ] },
  { name: "Deck Chair", slot_count: 4, angle: 90, widths: [ 0.25, 0.25, 0.25, 0.25 ] },
  { name: "Bayadère", slot_count: 5, angle: 0, widths: [ 0.4, 0.15, 0.1, 0.15, 0.2 ] },
  { name: "Hairline", slot_count: 2, angle: 0, widths: [ 0.94, 0.06 ] },
  { name: "Regatta", slot_count: 3, angle: 90, widths: [ 0.5, 0.25, 0.25 ] },
  { name: "Pinstripe", slot_count: 2, angle: 90, widths: [ 0.96, 0.04 ] },
  { name: "Cabana", slot_count: 3, angle: 0, widths: [ 0.34, 0.33, 0.33 ] },
  { name: "Ledger", slot_count: 6, angle: 0, widths: [ 0.3, 0.14, 0.14, 0.14, 0.14, 0.14 ] },
  { name: "Marquee", slot_count: 4, angle: 90, widths: [ 0.4, 0.2, 0.3, 0.1 ] },
  { name: "Boucle", slot_count: 3, angle: 90, widths: [ 0.6, 0.2, 0.2 ] },
  { name: "Shirting", slot_count: 4, angle: 0, widths: [ 0.55, 0.15, 0.15, 0.15 ] },
  { name: "Bias", slot_count: 3, angle: 30, widths: [ 0.5, 0.3, 0.2 ] },
  { name: "Chevron Ground", slot_count: 2, angle: 45, widths: [ 0.75, 0.25 ] },
  { name: "Barber", slot_count: 3, angle: 116.565, widths: [ 0.4, 0.4, 0.2 ] }
].freeze

COMPOSITIONS.each do |composition|
  widths = composition.delete(:widths)
  pattern = Pattern.find_or_create_by!(name: composition[:name]) { |new| new.assign_attributes(composition) }

  pattern.sequence.stripes.each_with_index do |stripe, index|
    stripe.update_column(:width, widths[index])
  end
end

# Rows, from the handoff's reference images.
#
# Lightning is the one that says what rows are for: 45° stripes have no
# vertical period an axis-aligned tile can use, and a half-period shift at
# every band boundary supplies one. Chevron and Coarse and Fine are the two
# transforms the references do not show.
ROWED = [
  { name: "Lightning", slot_count: 2, angle: 45, row_depth: 4, widths: [ 0.5, 0.5 ], rows: 4,
    transform: ->(row, index) { { phase: (index * 0.5) % 1 } } },
  { name: "Chevron", slot_count: 2, angle: 60, row_depth: 4, widths: [ 0.6, 0.4 ], rows: 6,
    transform: ->(_row, index) { { mirrored: index.odd? } } },
  { name: "Coarse and Fine", slot_count: 2, angle: 90, row_depth: 3, widths: [ 0.5, 0.5 ], rows: 3,
    transform: ->(_row, index) { { width_numerator: 1, width_denominator: index + 1 } } },
  { name: "Four Rows", slot_count: 4, angle: 90, row_depth: 4, widths: [ 0.25 ] * 4, rows: 4,
    transform: ->(_row, index) { { color_offset: index } } }
].freeze

ROWED.each do |composition|
  widths, count, transform = composition.values_at(:widths, :rows, :transform)
  attributes = composition.except(:widths, :rows, :transform)

  next if Pattern.exists?(name: attributes[:name])

  pattern = Pattern.create!(attributes)
  pattern.sequence.stripes.each_with_index { |stripe, index| stripe.update_column(:width, widths[index]) }
  pattern.divide_into_rows!(count)
  pattern.rows.each_with_index { |row, index| row.update!(transform.call(row, index)) }
end

# One colorway, from a palette written out here rather than fetched.
#
# Choosing a palette is Pandatone's part and needs PANDATONE_URL set;
# everything after the choosing is Stripeclub's and needs nothing. The palette
# is stored out of its rank order on purpose — it ranks cream, gold, red, ink
# — so the three rules that read a position and the one that reads a rank are
# telling apart on sight.
DRESSED = "Deck Chair".freeze

if (pattern = Pattern.find_by(name: DRESSED)) && pattern.colorways.none?
  palette = Pandatone::Palette.new(
    id: 1, name: "Deck Chair, in four",
    colors: [
      [ "Signal red", "#C1272D" ], [ "Cream", "#FAF8F4" ],
      [ "Ink", "#12120F" ], [ "Gold", "#E3B505" ]
    ].each_with_index.map do |(name, hex), index|
      Pandatone::Color.new(
        id: index, name: name, hex: hex,
        red: hex[1..2].to_i(16), green: hex[3..4].to_i(16), blue: hex[5..6].to_i(16)
      )
    end
  )

  colorway = Colorway.create!(pattern: pattern, palette: palette)
  colorway.bind(pattern.values.second, kind: :assigned_slot, slot: 0)
  colorway.bind(pattern.values.last, kind: :random, subset: [ 1, 3 ], seed: 3)

  puts "Dressed #{DRESSED} in #{palette.name}."
end

puts "Composed #{Pattern.count} patterns."
