# Dressing a pattern in one of Pandatone's palettes.
#
# Choosing is the only part of a colorway that needs Pandatone at all.
# Everything after the choosing reads the snapshot, which is why a colorway
# goes on rendering when Pandatone is down and why what Pandatone has done
# since is drift rather than an update.
class Patterns::ColorwaysController < ApplicationController
  before_action :set_pattern
  before_action :set_colorway, only: %i[ destroy drift ]

  # The palette picker. Every palette Pandatone has, ordered so the ones that
  # can dress this pattern come first — demoted and not excluded, because a
  # slot taken away with "−" brings the rest back into range.
  def new
    Pandatone::Catalog.forget! if params[:refresh]

    @catalog = Pandatone::Catalog.current
    @serving, @demoted = @catalog.palettes.partition { |palette| palette.serves?(@pattern.slot_count) }
  rescue Pandatone::Error => e
    @unreachable = e
  end

  def create
    palette = Pandatone::Catalog.current.palettes.find { |candidate| candidate.id == params[:palette_id].to_i }
    return redirect_to new_pattern_colorway_path(@pattern), alert: "That palette is not in the catalogue." if palette.nil?

    colorway = @pattern.colorways.create!(palette: palette)

    redirect_to @pattern, notice: "#{@pattern.name} dressed in #{colorway.snapshot.palette_name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_pattern_colorway_path(@pattern), alert: e.record.errors.full_messages.to_sentence
  rescue Pandatone::Error => e
    redirect_to new_pattern_colorway_path(@pattern), alert: e.message
  end

  def destroy
    @colorway.destroy!

    redirect_to @pattern, notice: "Colorway removed. The pattern is undressed, not changed."
  end

  # Reported, never applied. A design that was finished should not change
  # because someone else opened another tool.
  def drift
    Pandatone::Catalog.forget!
    live = Pandatone::Catalog.current.palettes.find { |palette| palette.id == @colorway.palette_id }

    redirect_to @pattern, notice: drift_notice(live)
  rescue Pandatone::Error => e
    redirect_to @pattern, alert: e.message
  end

  private
    def set_pattern
      @pattern = Pattern.find(params[:pattern_id])
    end

    def set_colorway
      @colorway = @pattern.colorways.find(params[:id])
    end

    def drift_notice(live)
      return "Pandatone no longer has that palette. The snapshot is all there is of it now." if live.nil?

      if @colorway.drifted_from?(live)
        "#{live.name} has moved in Pandatone since this snapshot. Nothing here has changed."
      else
        "#{live.name} is unchanged since this snapshot."
      end
    end
end
