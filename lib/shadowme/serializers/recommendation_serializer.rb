require 'oj'

module ShadowMe
  class RecommendationSerializer
    # Converts SeatRecommendation model to a Hash.
    def self.to_hash(rec, include_steps: false)
      hash = { recommended_side: rec.recommended_side, left_exposure_minutes: rec.left_exposure_minutes,
               right_exposure_minutes: rec.right_exposure_minutes, night_exposure_minutes: rec.night_exposure_minutes,
               front_behind_exposure_minutes: rec.front_behind_exposure_minutes, confidence: rec.confidence }
      msg = rec.message
      steps = rec.steps
      route_idx = rec.route_index
      hash[:message] = msg if msg
      hash[:steps] = steps if include_steps && steps&.any?
      hash[:route_index] = route_idx if route_idx
      hash
    end

    # Converts SeatRecommendation model to a JSON string using Oj.
    def self.serialize(recommendation, include_steps: false)
      Oj.dump(to_hash(recommendation, include_steps: include_steps), mode: :compat)
    end
  end
end
