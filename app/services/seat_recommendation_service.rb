class SeatRecommendationService
  # Recommends which side of the vehicle to sit on to minimize sun exposure.
  # left_exposure_seconds: total exposure seconds on the left side
  # right_exposure_seconds: total exposure seconds on the right side
  # Returns a SeatRecommendation model.
  def self.recommend(left_exposure_seconds:, right_exposure_seconds:, is_entirely_night: false, steps: [], route_index: nil)
    if is_entirely_night
      return SeatRecommendation.new(
        recommended_side: :either,
        left_exposure_minutes: 0,
        right_exposure_minutes: 0,
        confidence: :high,
        message: "It is night time, enjoy your journey!",
        steps: steps,
        route_index: route_index
      )
    end

    left_seconds = left_exposure_seconds.to_f
    right_seconds = right_exposure_seconds.to_f

    # "The recommended side is the side receiving less sunlight."
    # If they are equal, it defaults to :right as per the `<` comparison.
    recommended_side = left_seconds < right_seconds ? :left : :right

    total_exposure = left_seconds + right_seconds

    confidence = if total_exposure <= 0
                   :low
                 else
                   # Calculate difference percentage relative to total exposure
                   diff_pct = ((left_seconds - right_seconds).abs / total_exposure) * 100.0
                   
                   # Confidence thresholds:
                   # 0-10%   => low
                   # 10-30%  => medium
                   # 30%+    => high
                   if diff_pct <= 10.0
                     :low
                   elsif diff_pct <= 30.0
                     :medium
                   else
                     :high
                   end
                 end

    # Convert to minutes and round to the nearest integer for serialization
    left_minutes = (left_seconds / 60.0).round
    right_minutes = (right_seconds / 60.0).round

    message = "You should sit on the #{recommended_side} side of the vehicle to minimize direct sunlight exposure."

    SeatRecommendation.new(
      recommended_side: recommended_side,
      left_exposure_minutes: left_minutes,
      right_exposure_minutes: right_minutes,
      confidence: confidence,
      message: message,
      steps: steps,
      route_index: route_index
    )
  end
end
