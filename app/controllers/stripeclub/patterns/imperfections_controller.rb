# Round two: how far the pattern is allowed to be off.
module Stripeclub
  class Patterns::ImperfectionsController < ApplicationController
    before_action :set_pattern

    def update
      imperfection = @pattern.imperfection || @pattern.build_imperfection

      if imperfection.update(imperfection_params)
        redirect_to finish, notice: imperfection.any? ? "Roughened." : "Clean again."
      else
        redirect_to finish, alert: imperfection.errors.full_messages.to_sentence
      end
    end

    def destroy
      @pattern.imperfection&.destroy

      redirect_to finish, notice: "Imperfection removed. The composition was never touched."
    end

    private
      def set_pattern
        @pattern = Pattern.find(params[:pattern_id])
      end

      # Back to the surface the roughness lives on.
      def finish
        pattern_path(@pattern, section: "finish")
      end

      def imperfection_params
        params.expect(imperfection: [
          :wobble, :wobble_frequency, :wobble_octaves,
          :variance, :texture, :texture_frequency, :seed
        ])
      end
  end
end
