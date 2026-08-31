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

  # Which parts of the structure are still doing value work.
  #
  # A value bound to its rank shows the step of the ladder it sits on, because
  # that step is what decides its colour. A value bound to a rule shows a
  # hatch instead: its rank has stopped mattering, and a swatch that went on
  # showing one would be showing something the colorway no longer reads.
  #
  # The hatch is never the only thing saying so — every place this is used
  # names the rule in words beside it — because a pattern in a small square is
  # exactly the kind of signal some readers do not get.
  def slot_swatch(value, colorway: nil)
    rule = colorway&.rule_for(value)

    if rule.nil? || rule.binds_to_rank?
      tag.span(class: "slot-swatch", style: "background: #{ValueScale.new(value.pattern).gray_for(value).hex}")
    else
      tag.span(class: "slot-swatch slot-swatch--ruled")
    end
  end

  # A slot nothing draws is what "+" leaves behind: a rank that exists and is
  # not in the repeat yet.
  def drawn_by?(pattern, value)
    pattern.sequence.stripes.any? { |stripe| stripe.value_id == value.id }
  end

  # A row's transform as one control in one table cell.
  #
  # its-swiss's form builder writes a label above a control down the width of
  # a form, which is the right shape for a form and the wrong one for a table
  # of four small numbers. The .field wrapper is kept, so the control is
  # styled the way every other control in the application is; the label moves
  # off screen, because the column heading already says what it is and a
  # second copy in every cell would be read out on every one.
  def row_field(row, attribute, label:, **options)
    id = "rows_#{row.id}_#{attribute}"

    tag.div(class: "field") do
      safe_join([
        tag.label(label, class: "visually-hidden", for: id),
        number_field_tag("rows[#{row.id}][#{attribute}]", row.public_send(attribute), id: id, **options)
      ])
    end
  end

  def row_mirror_field(row)
    id = "rows_#{row.id}_mirrored"

    tag.div(class: "field field--inline") do
      safe_join([
        hidden_field_tag("rows[#{row.id}][mirrored]", 0, id: nil),
        check_box_tag("rows[#{row.id}][mirrored]", 1, row.mirrored?, id: id),
        tag.label("Mirror row #{row.position + 1}", class: "visually-hidden", for: id)
      ])
    end
  end

  # A palette as the picker shows it: its colours in luminance rank, drawn as
  # the grays of their own lightness.
  #
  # Not in their own colours, and that is the handoff's call rather than a
  # shortcut. The preview is the one place colour belongs, and what a palette
  # is *for* here is its distribution of value — which is the thing you cannot
  # see when six hues are shouting. Choose on the ladder, then look at the
  # preview.
  def palette_strip(palette)
    tag.ol(class: "palette-strip") do
      safe_join(palette.ranked.map { |color| palette_swatch(color) })
    end
  end

  def palette_swatch(color)
    tag.li do
      safe_join([
        tag.span(class: "palette-swatch", style: "background: #{Luminance.gray(color.luminance)}"),
        tag.span(color.name, class: "palette-swatch__name")
      ])
    end
  end

  def rule_name(rule)
    {
      "auto_value_match" => "By rank", "assigned_slot" => "Palette slot #{rule.slot}",
      "increment" => "Increment from #{rule.start} by #{rule.step}",
      "random" => "Random of #{rule.subset.to_a.size}, seeded"
    }.fetch(rule.kind)
  end
end
