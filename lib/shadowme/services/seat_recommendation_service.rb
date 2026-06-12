module ShadowMe
  class SeatRecommendationService
    # Recommends which side of the vehicle to sit on to minimize sun exposure.
    # Returns a SeatRecommendation model.
    def self.recommend(**args)
      left_m, right_m, night_m, front_m = convert_to_minutes(args)

      if args[:is_entirely_night]
        build_night_recommendation(night_m, args[:steps], args[:route_index])
      else
        build_day_recommendation(args, left_m, right_m, night_m, front_m)
      end
    end

    def self.convert_to_minutes(args)
      [
        (args[:left_exposure_seconds].to_f / 60.0).round,
        (args[:right_exposure_seconds].to_f / 60.0).round,
        (args[:night_exposure_seconds].to_f / 60.0).round,
        (args[:front_behind_exposure_seconds].to_f / 60.0).round
      ]
    end

    def self.build_night_recommendation(night_minutes, steps, route_index)
      SeatRecommendation.new(
        recommended_side: :either, left_exposure_minutes: 0, right_exposure_minutes: 0,
        confidence: :high, night_exposure_minutes: night_minutes, front_behind_exposure_minutes: 0,
        message: 'It is night time, enjoy your journey!', steps: steps, route_index: route_index
      )
    end

    def self.build_day_recommendation(args, left_m, right_m, night_m, front_m)
      left_sec = args[:left_exposure_seconds].to_f
      right_sec = args[:right_exposure_seconds].to_f

      side, confidence, msg = calculate_side_and_confidence(left_sec, right_sec)
      SeatRecommendation.new(
        recommended_side: side, left_exposure_minutes: left_m, right_exposure_minutes: right_m,
        confidence: confidence, night_exposure_minutes: night_m, front_behind_exposure_minutes: front_m,
        message: msg, steps: args[:steps], route_index: args[:route_index]
      )
    end

    def self.calculate_side_and_confidence(left_sec, right_sec)
      if left_sec.zero? && right_sec.zero?
        [:either, :high, 'Either side is fine, there is no direct side sunlight exposure.']
      else
        side = left_sec < right_sec ? :left : :right
        pct = ((left_sec - right_sec).abs / (left_sec + right_sec)) * 100.0
        conf = confidence_for_pct(pct)
        [side, conf, "You should sit on the #{side} side of the vehicle to minimize direct sunlight exposure."]
      end
    end

    def self.confidence_for_pct(pct)
      if pct <= 10.0
        :low
      elsif pct <= 30.0
        :medium
      else
        :high
      end
    end

    private_class_method :convert_to_minutes, :build_night_recommendation,
                         :build_day_recommendation, :calculate_side_and_confidence,
                         :confidence_for_pct
  end
end
