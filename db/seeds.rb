# A few patterns to look at. Structure only — none of these has a palette,
# because none of them needs one to be a pattern.
#
# Angles are the two the renderer lays out directly until step five.
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
  { name: "Shirting", slot_count: 4, angle: 0, widths: [ 0.55, 0.15, 0.15, 0.15 ] }
].freeze

COMPOSITIONS.each do |composition|
  widths = composition.delete(:widths)
  pattern = Pattern.find_or_create_by!(name: composition[:name]) { |new| new.assign_attributes(composition) }

  pattern.sequence.stripes.each_with_index do |stripe, index|
    stripe.update_column(:width, widths[index])
  end
end

puts "Composed #{Pattern.count} patterns."
