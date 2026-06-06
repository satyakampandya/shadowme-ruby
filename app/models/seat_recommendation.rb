class SeatRecommendation
  attr_reader :recommended_side, :left_exposure_minutes, :right_exposure_minutes, :confidence, :message

  def initialize(recommended_side:, left_exposure_minutes:, right_exposure_minutes:, confidence:, message: nil)
    @recommended_side = recommended_side.to_s
    @left_exposure_minutes = left_exposure_minutes.to_i
    @right_exposure_minutes = right_exposure_minutes.to_i
    @confidence = confidence.to_s
    @message = message ? message.to_s : nil
  end
end
