class RouteAnalyzerService
  # Maximum duration in seconds for a single step segment to ensure accurate sun calculations (10 minutes)
  MAX_STEP_DURATION = 600

  # Processes all RouteSteps sequentially to accumulate sun exposure.
  # steps: Array of RouteStep models
  # departure_time: Time object of the departure time
  # Returns: Hash containing total left and right exposure in seconds
  def self.analyze(steps:, departure_time:)
    processed_steps = []

    steps.each do |step|
      if step.duration > MAX_STEP_DURATION
        segments_count = (step.duration.to_f / MAX_STEP_DURATION).ceil

        segments_count.times do |i|
          fraction_start = i.to_f / segments_count
          fraction_end = (i + 1).to_f / segments_count

          seg_start_lat = step.start_lat + (step.end_lat - step.start_lat) * fraction_start
          seg_start_lng = step.start_lng + (step.end_lng - step.start_lng) * fraction_start
          seg_end_lat = step.start_lat + (step.end_lat - step.start_lat) * fraction_end
          seg_end_lng = step.start_lng + (step.end_lng - step.start_lng) * fraction_end

          seg_duration = step.duration / segments_count
          seg_distance = step.distance / segments_count

          # Handle rounding difference on the last segment to preserve exact total sum
          if i == segments_count - 1
            seg_duration = step.duration - (seg_duration * (segments_count - 1))
            seg_distance = step.distance - (seg_distance * (segments_count - 1))
          end

          processed_steps << RouteStep.new(
            start_lat: seg_start_lat,
            start_lng: seg_start_lng,
            end_lat: seg_end_lat,
            end_lng: seg_end_lng,
            duration: seg_duration,
            distance: seg_distance
          )
        end
      else
        processed_steps << step
      end
    end

    left_exposure_seconds = 0
    right_exposure_seconds = 0
    night_exposure_seconds = 0
    accumulated_duration_seconds = 0
    night_steps_count = 0
    steps_details = []

    processed_steps.each do |step|
      analysis = StepAnalyzerService.analyze(
        route_step: step,
        trip_start_time: departure_time,
        accumulated_duration_seconds: accumulated_duration_seconds
      )

      # If the sun is at or below the horizon, it is night time for this step
      if analysis[:sun_position].elevation <= 0.0
        night_steps_count += 1
        night_exposure_seconds += step.duration
      else
        case analysis[:sun_side]
        when :left
          left_exposure_seconds += step.duration
        when :right
          right_exposure_seconds += step.duration
        end
      end

      steps_details << {
        start_lat: step.start_lat.to_f,
        start_lng: step.start_lng.to_f,
        end_lat: step.end_lat.to_f,
        end_lng: step.end_lng.to_f,
        duration: step.duration.to_i,
        distance: step.distance.to_i,
        midpoint_lat: analysis[:midpoint_lat].to_f,
        midpoint_lng: analysis[:midpoint_lng].to_f,
        midpoint_time: analysis[:midpoint_time].iso8601,
        bearing: analysis[:bearing].to_f,
        sun_azimuth: analysis[:sun_position].azimuth.to_f,
        sun_elevation: analysis[:sun_position].elevation.to_f,
        sun_side: analysis[:sun_side].to_s
      }

      accumulated_duration_seconds += step.duration
    end

    {
      left_exposure_seconds: left_exposure_seconds,
      right_exposure_seconds: right_exposure_seconds,
      night_exposure_seconds: night_exposure_seconds,
      is_entirely_night: (night_steps_count == processed_steps.size),
      steps: steps_details
    }
  end
end
