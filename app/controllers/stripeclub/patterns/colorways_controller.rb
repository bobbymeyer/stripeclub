# Dressing a pattern in one of Pandatone's palettes.
#
# Choosing is the only part of a colorway that needs Pandatone at all.
# Everything after the choosing reads the snapshot, which is why a colorway
# goes on rendering when Pandatone is down and why what Pandatone has done
# since is drift rather than an update. The asking is Pandatone's dresser's;
# what is here is the pattern's side of it.
module Stripeclub
  class Patterns::ColorwaysController < ApplicationController
    include Pandatone::Dresser::Dressing

    before_action :set_pattern
    before_action :set_colorway, only: %i[ destroy drift ]

    # The palette picker. Every palette Pandatone has, ordered so the ones that
    # can dress this pattern come first — demoted and not excluded, because a
    # slot taken away with "−" brings the rest back into range.
    def new
      @serving, @demoted = catalog.palettes.partition { |palette| palette.serves?(@pattern.slot_count) }
    rescue Pandatone::Dresser::Error => e
      @unreachable = e
    end

    def create
      palette = palette_from_catalog(params[:palette_id])
      return redirect_to new_pattern_colorway_path(@pattern), alert: "That palette is not in the catalogue." if palette.nil?

      colorway = @pattern.colorways.create!(palette: palette)

      redirect_to @pattern, notice: "#{@pattern.name} dressed in #{colorway.snapshot.palette_name}."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_pattern_colorway_path(@pattern), alert: e.record.errors.full_messages.to_sentence
    rescue Pandatone::Dresser::Error => e
      redirect_to new_pattern_colorway_path(@pattern), alert: e.message
    end

    def destroy
      @colorway.destroy!

      redirect_to @pattern, notice: "Colorway taken off. The pattern is undressed, not changed."
    end

    # Reported, never applied. A design that was finished should not change
    # because someone else opened another tool.
    def drift
      redirect_to @pattern, notice: drift_report(@colorway)
    rescue Pandatone::Dresser::Error => e
      redirect_to @pattern, alert: e.message
    end

    private
      def set_pattern
        @pattern = Pattern.find(params[:pattern_id])
      end

      def set_colorway
        @colorway = @pattern.colorways.find(params[:id])
      end
  end
end
