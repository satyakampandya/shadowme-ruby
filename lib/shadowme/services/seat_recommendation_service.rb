module ShadowMe
  module SeatRecommendationService
    # ponytail: simplified seat recommendation math and formatting
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.recommend(**args)
      left_m = (args[:left_exposure_seconds].to_f / 60.0).round
      right_m = (args[:right_exposure_seconds].to_f / 60.0).round
      night_m = (args[:night_exposure_seconds].to_f / 60.0).round
      front_m = (args[:front_behind_exposure_seconds].to_f / 60.0).round

      if args[:is_entirely_night]
        SeatRecommendation.new(
          recommended_side: :either, left_exposure_minutes: 0, right_exposure_minutes: 0,
          confidence: :high, night_exposure_minutes: night_m, front_behind_exposure_minutes: 0,
          message: 'It is night time, enjoy your journey!', steps: args[:steps], route_index: args[:route_index]
        )
      elsif left_m.zero? && right_m.zero?
        SeatRecommendation.new(
          recommended_side: :either, left_exposure_minutes: 0, right_exposure_minutes: 0,
          confidence: :high, night_exposure_minutes: night_m, front_behind_exposure_minutes: front_m,
          message: 'Either side is fine, there is no direct side sunlight exposure.',
          steps: args[:steps], route_index: args[:route_index]
        )
      else
        side = left_m < right_m ? :left : :right
        total = args[:left_exposure_seconds].to_f + args[:right_exposure_seconds].to_f
        diff = (args[:left_exposure_seconds].to_f - args[:right_exposure_seconds].to_f).abs
        pct = total.zero? ? 0.0 : (diff / total) * 100.0
        conf = if pct <= 10.0 then :low
               elsif pct <= 30.0 then :medium
               else :high
               end
        SeatRecommendation.new(
          recommended_side: side, left_exposure_minutes: left_m, right_exposure_minutes: right_m,
          confidence: conf, night_exposure_minutes: night_m, front_behind_exposure_minutes: front_m,
          message: "You should sit on the #{side} side of the vehicle to minimize direct sunlight exposure.",
          steps: args[:steps], route_index: args[:route_index]
        )
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
