module ShadowMe
  class SeatRecommendation
    attr_reader :recommended_side, :left_exposure_minutes, :right_exposure_minutes, :night_exposure_minutes,
                :front_behind_exposure_minutes, :confidence, :message, :steps, :route_index

    def initialize(recommended_side:, left_exposure_minutes:, right_exposure_minutes:, confidence:,
                   night_exposure_minutes: 0, front_behind_exposure_minutes: 0, message: nil, steps: [], route_index: nil)
      @recommended_side = recommended_side.to_s
      @left_exposure_minutes = left_exposure_minutes.to_i
      @right_exposure_minutes = right_exposure_minutes.to_i
      @night_exposure_minutes = night_exposure_minutes.to_i
      @front_behind_exposure_minutes = front_behind_exposure_minutes.to_i
      @confidence = confidence.to_s
      @message = message&.to_s
      @steps = steps
      @route_index = route_index
    end
  end
end
