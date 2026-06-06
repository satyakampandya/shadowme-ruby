class RouteAnalyzerService
  # Processes all RouteSteps sequentially to accumulate sun exposure.
  # steps: Array of RouteStep models
  # departure_time: Time object of the departure time
  # Returns: Hash containing total left and right exposure in seconds
  def self.analyze(steps:, departure_time:)
    left_exposure_seconds = 0
    right_exposure_seconds = 0
    accumulated_duration_seconds = 0
    night_steps_count = 0

    steps.each do |step|
      analysis = StepAnalyzerService.analyze(
        route_step: step,
        trip_start_time: departure_time,
        accumulated_duration_seconds: accumulated_duration_seconds
      )

      # If the sun is at or below the horizon, it is night time for this step
      if analysis[:sun_position].elevation <= 0.0
        night_steps_count += 1
      else
        case analysis[:sun_side]
        when :left
          left_exposure_seconds += step.duration
        when :right
          right_exposure_seconds += step.duration
        end
      end

      accumulated_duration_seconds += step.duration
    end

    {
      left_exposure_seconds: left_exposure_seconds,
      right_exposure_seconds: right_exposure_seconds,
      is_entirely_night: (night_steps_count == steps.size)
    }
  end
end
