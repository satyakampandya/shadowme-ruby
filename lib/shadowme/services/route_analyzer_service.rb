module ShadowMe
  module RouteAnalyzerService
    MAX_STEP_DURATION = 600

    # ponytail: simplified step segmentation and sequential exposure accumulation
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
    def self.analyze(steps:, departure_time:, include_steps: false)
      processed = steps.flat_map { |s| s.duration > MAX_STEP_DURATION ? subdivide_step(s) : s }

      left = right = night = front_behind = accumulated = night_steps = 0
      steps_detail = []

      processed.each do |step|
        analysis = StepAnalyzerService.analyze(
          route_step: step, trip_start_time: departure_time, accumulated_duration_seconds: accumulated
        )
        sun = analysis[:sun_position]

        if sun.elevation <= 0.0
          night_steps += 1
          night += step.duration
        else
          case analysis[:sun_side]
          when :left then left += step.duration
          when :right then right += step.duration
          when :front, :behind then front_behind += step.duration
          end
        end

        if include_steps
          steps_detail << {
            start_lat: step.start_lat, start_lng: step.start_lng, end_lat: step.end_lat, end_lng: step.end_lng,
            duration: step.duration, distance: step.distance,
            midpoint_lat: analysis[:midpoint_lat], midpoint_lng: analysis[:midpoint_lng],
            midpoint_time: analysis[:midpoint_time].iso8601, bearing: analysis[:bearing],
            sun_azimuth: sun.azimuth, sun_elevation: sun.elevation, sun_side: analysis[:sun_side].to_s
          }
        end
        accumulated += step.duration
      end

      {
        left_exposure_seconds: left,
        right_exposure_seconds: right,
        night_exposure_seconds: night,
        front_behind_exposure_seconds: front_behind,
        is_entirely_night: (night_steps == processed.size),
        steps: steps_detail
      }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.subdivide_step(step)
      # ponytail: simplified linear subdivision math
      count = (step.duration.to_f / MAX_STEP_DURATION).ceil
      dur = step.duration / count
      dist = step.distance / count
      count.times.map do |i|
        f1 = i.to_f / count
        f2 = (i + 1).to_f / count
        last = i == count - 1
        RouteStep.new(
          start_lat: step.start_lat + ((step.end_lat - step.start_lat) * f1),
          start_lng: step.start_lng + ((step.end_lng - step.start_lng) * f1),
          end_lat: step.start_lat + ((step.end_lat - step.start_lat) * f2),
          end_lng: step.start_lng + ((step.end_lng - step.start_lng) * f2),
          duration: last ? step.duration - (dur * i) : dur,
          distance: last ? step.distance - (dist * i) : dist
        )
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    private_class_method :subdivide_step
  end
end
