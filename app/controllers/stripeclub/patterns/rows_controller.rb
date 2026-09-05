# Rows: the block as a whole, and what is done inside one of them.
module Stripeclub
  class Patterns::RowsController < ApplicationController
    # More rows than this and each band is thinner than the hairline between
    # them, which is a pattern nobody asked for and a page nobody can use.
    MOST = 24

    # Heights are not among them. A height is what the block divides between its
    # rows, and changing one without the others would leave the block short.
    TRANSFORMS = %i[ phase color_offset mirrored width_numerator width_denominator ].freeze

    before_action :set_pattern

    def create
      count = params[:count].to_i.clamp(1, MOST)
      @pattern.divide_into_rows!(count)

      redirect_to @pattern, notice: "Broken into #{helpers.pluralize(count, "row")}."
    end

    # All of them at once, in one transaction: the four transforms are read
    # across the rows rather than one row at a time — a phase shift is only a
    # phase shift relative to the band above it — so they are saved that way too.
    def update
      submitted = params.require(:rows)

      @pattern.transaction do
        @pattern.rows.each do |row|
          attributes = submitted[row.id.to_s]

          row.update!(attributes.permit(*TRANSFORMS)) if attributes.present?
        end
      end

      redirect_to @pattern, notice: "Rows changed."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to @pattern, alert: e.record.errors.full_messages.to_sentence
    end

    def destroy
      @pattern.rows.destroy_all

      redirect_to @pattern, notice: "Rows removed. The tile is one band again."
    end

    private
      def set_pattern
        @pattern = Pattern.find(params[:pattern_id])
      end
  end
end
