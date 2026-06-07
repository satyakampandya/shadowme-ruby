require 'oj'

class RecommendationSerializer
  # Converts SeatRecommendation model to a Hash.
  def self.to_hash(recommendation)
    hash = {
      recommended_side: recommendation.recommended_side,
      left_exposure_minutes: recommendation.left_exposure_minutes,
      right_exposure_minutes: recommendation.right_exposure_minutes,
      night_exposure_minutes: recommendation.respond_to?(:night_exposure_minutes) ? recommendation.night_exposure_minutes : 0,
      confidence: recommendation.confidence
    }
    hash[:message] = recommendation.message if recommendation.message
    hash[:steps] = recommendation.steps if recommendation.steps && !recommendation.steps.empty?
    hash[:route_index] = recommendation.route_index if recommendation.respond_to?(:route_index) && !recommendation.route_index.nil?
    hash
  end

  # Converts SeatRecommendation model to a JSON string using Oj.
  def self.serialize(recommendation)
    Oj.dump(to_hash(recommendation), mode: :compat)
  end
end
