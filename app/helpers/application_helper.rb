module ApplicationHelper
  # A pattern, drawn.
  #
  # Handed a colorway it draws the pattern wearing it; handed a pattern on its
  # own it draws it in value, which is not a placeholder for the coloured
  # version — a pattern is structure, so its values are what it actually is.
  def pattern_preview(subject, size: 240, period: 60, **options)
    dressing = subject.is_a?(Pattern) ? ValueScale.new(subject) : subject

    tag.div(SvgPattern.new(dressing, size: size, period: period).to_s,
      **options, class: token_list("preview", options[:class]))
  end

  # The two axes have names worth using; everything else is a number of
  # degrees and reads better as one.
  def angle_in_words(pattern)
    case pattern.angle
    when SvgPattern::VERTICAL then "Vertical"
    when SvgPattern::HORIZONTAL then "Horizontal"
    else "#{pattern.angle.to_f.round(3).to_s.delete_suffix(".0")}°"
    end
  end

  # Tiling is a status, so it is reported for every mode at once rather than
  # for whichever one happens to be selected. A pattern that closes as an SVG
  # pattern and not as an unbroken tile is a normal pattern, and seeing both
  # at once is what makes that legible.
  def tiling_modes(pattern)
    Tiling::MODES.index_with { |mode| Tiling.new(pattern, mode: mode) }
  end

  def tiling_mode_name(mode)
    { svg_pattern: "SVG pattern", row_broken: "Row-broken tile", unbroken: "Unbroken tile" }.fetch(mode)
  end

  # Words, not a colour and not only a mark. its-swiss's own rule is that no
  # signal rests on colour alone, and a red cross is exactly that.
  def tiling_status_words(tiling)
    { seamless: "Tiles", seamless_with_rows: "Tiles, with rows", does_not_tile: "Doesn't tile" }
      .fetch(tiling.status)
  end

  # Slot 0 is the ground, and calling it that everywhere is the difference
  # between a rule someone has to remember and one the interface states.
  def slot_name(value)
    value.position.zero? ? "Ground" : "Slot #{value.position}"
  end
end
