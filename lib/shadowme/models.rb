# ponytail: defined value objects compactly to eliminate boilerplate and multiple files.
module ShadowMe
  # rubocop:disable Metrics/AbcSize
  RouteStep = Struct.new(:start_lat, :start_lng, :end_lat, :end_lng, :duration, :distance, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.start_lat = start_lat.to_f
      self.start_lng = start_lng.to_f
      self.end_lat = end_lat.to_f
      self.end_lng = end_lng.to_f
      self.duration = duration.to_i
      self.distance = distance.to_i
    end
  end
  # rubocop:enable Metrics/AbcSize

  SunPosition = Struct.new(:azimuth, :elevation, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.azimuth = azimuth.to_f
      self.elevation = elevation.to_f
    end
  end

  TripRequest = Struct.new(:source, :destination, :departure_time, :route_index, :include_steps, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.route_index ||= 0
      self.include_steps = !!include_steps
    end
  end

  # rubocop:disable Metrics/AbcSize
  SeatRecommendation = Struct.new(:recommended_side, :left_exposure_minutes, :right_exposure_minutes,
                                  :night_exposure_minutes, :front_behind_exposure_minutes,
                                  :confidence, :message, :steps, :route_index, keyword_init: true) do
    def initialize(**kwargs)
      super
      self.recommended_side = recommended_side.to_s
      self.left_exposure_minutes = left_exposure_minutes.to_i
      self.right_exposure_minutes = right_exposure_minutes.to_i
      self.night_exposure_minutes = night_exposure_minutes.to_i
      self.front_behind_exposure_minutes = front_behind_exposure_minutes.to_i
      self.confidence = confidence.to_s
      self.message = message&.to_s
      self.steps ||= []
    end

    def to_hash(include_steps: false)
      # ponytail: serialization logic directly on the model
      hash = { recommended_side: recommended_side, left_exposure_minutes: left_exposure_minutes,
               right_exposure_minutes: right_exposure_minutes, night_exposure_minutes: night_exposure_minutes,
               front_behind_exposure_minutes: front_behind_exposure_minutes, confidence: confidence }
      hash[:message] = message if message
      hash[:steps] = steps if include_steps && steps&.any?
      hash[:route_index] = route_index if route_index
      hash
    end
  end
  # rubocop:enable Metrics/AbcSize
end
