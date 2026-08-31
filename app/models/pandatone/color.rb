# One of Pandatone's colours, as far as Stripeclub cares: something to put in
# a slot, and a measure of how light it looks so the slots can be ranked.
class Pandatone::Color
  attr_reader :id, :name, :hex, :red, :green, :blue, :tags

  def self.from_json(json)
    rgb = json["rgb"] || {}

    new(
      id: json["id"], name: json["name"], hex: json["hex"], tags: json["tags"] || [],
      red: rgb["r"], green: rgb["g"], blue: rgb["b"]
    )
  end

  def initialize(id:, name:, hex:, red: nil, green: nil, blue: nil, tags: [])
    @id, @name, @hex, @tags = id, name, hex, tags
    @red, @green, @blue = red, green, blue
  end

  # Measured here, not fetched: Pandatone stores colour and says in as many
  # words that the brightness it keeps is not perceptual.
  #
  # Pandatone sends both spellings and they agree, so the channels are
  # preferred and the hex is the fallback for a payload that carried only one.
  def luminance
    @luminance ||=
      if red && green && blue
        Luminance.of(red, green, blue)
      else
        Luminance.of_hex(hex)
      end
  end
end
