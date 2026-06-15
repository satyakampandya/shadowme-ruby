require 'oj'

module ShadowMe
  module RecommendationSerializer
    # ponytail: clean static serializer functions
    # rubocop:disable Metrics/AbcSize
    def self.to_hash(rec, include_steps: false)
      hash = { recommended_side: rec.recommended_side, left_exposure_minutes: rec.left_exposure_minutes,
               right_exposure_minutes: rec.right_exposure_minutes, night_exposure_minutes: rec.night_exposure_minutes,
               front_behind_exposure_minutes: rec.front_behind_exposure_minutes, confidence: rec.confidence }
      hash[:message] = rec.message if rec.message
      hash[:steps] = rec.steps if include_steps && rec.steps&.any?
      hash[:route_index] = rec.route_index if rec.route_index
      hash
    end
    # rubocop:enable Metrics/AbcSize

    def self.serialize(rec, include_steps: false)
      Oj.dump(to_hash(rec, include_steps: include_steps), mode: :compat)
    end
  end
end
