# Pandatone is the colour tool. Stripeclub composes in value and asks
# Pandatone what those values are wearing, the way a later tool will ask
# Stripeclub for a pattern.
#
# Every failure here is its own class rather than a nil, because each of them
# would otherwise arrive as "Pandatone has no palettes" — and a catalogue that
# is empty because a token expired is worse than one that says so.
module Pandatone
  Error = Class.new(StandardError)

  # The token was refused, or there was none to send.
  Unauthorized = Class.new(Error)

  # Asked for a palette that is not there.
  NotFound = Class.new(Error)

  # Nothing answered: refused, timed out, or no such host.
  Unreachable = Class.new(Error)
end
