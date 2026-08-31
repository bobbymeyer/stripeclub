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

  # The two angles the renderer lays out directly. Step five adds the rest,
  # and this is where they will read as degrees.
  def angle_in_words(pattern)
    case pattern.angle
    when SvgPattern::VERTICAL then "Vertical"
    when SvgPattern::HORIZONTAL then "Horizontal"
    else "#{pattern.angle.to_f.round(1)}°"
    end
  end

  def angle_choices
    [ [ "Vertical", SvgPattern::VERTICAL ], [ "Horizontal", SvgPattern::HORIZONTAL ] ]
  end

  # Slot 0 is the ground, and calling it that everywhere is the difference
  # between a rule someone has to remember and one the interface states.
  def slot_name(value)
    value.position.zero? ? "Ground" : "Slot #{value.position}"
  end
end
