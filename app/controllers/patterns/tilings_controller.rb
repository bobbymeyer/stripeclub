# Snap To Tiling.
class Patterns::TilingsController < ApplicationController
  def update
    pattern = Pattern.find(params[:pattern_id])
    snap = SnapToTiling.new(pattern)

    if snap.changed?
      snap.apply!
      redirect_to pattern, notice: "Snapped to #{pattern.angle.to_f.round(3)}°, a slope of #{snap.slope_as_ratio}."
    else
      redirect_to pattern, notice: "#{pattern.name} already closes on an unbroken tile."
    end
  end
end
