# "+" and "−".
class Patterns::SlotsController < ApplicationController
  before_action :set_pattern

  def create
    @pattern.add_value!

    redirect_to @pattern, notice: "A slot added. Nothing draws it yet."
  end

  def destroy
    @pattern.remove_value!

    redirect_to @pattern, notice: "The last slot taken away."
  rescue Pattern::ValueInUse => e
    redirect_to @pattern, alert: e.message.upcase_first
  end

  private
    def set_pattern
      @pattern = Pattern.find(params[:pattern_id])
    end
end
