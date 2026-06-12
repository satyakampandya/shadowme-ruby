module ShadowMe
  class RouteAnalyzerService
    # Maximum duration in seconds for a single step segment to ensure accurate sun calculations (10 minutes)
    MAX_STEP_DURATION = 600

    # Processes all RouteSteps sequentially to accumulate sun exposure.
    # steps: Array of RouteStep models
    # departure_time: Time object of the departure time
    # Returns: Hash containing total left and right exposure in seconds
    def self.analyze(steps:, departure_time:, include_steps: false)
      processed_steps = subdivide_steps(steps)
      accumulate_exposure(processed_steps, departure_time, include_steps)
    end

    def self.subdivide_steps(steps)
      processed_steps = []
      steps.each do |step|
        if step.duration > MAX_STEP_DURATION
          processed_steps.concat(subdivide_step(step))
        else
          processed_steps << step
        end
      end
      processed_steps
    end

    def self.subdivide_step(step)
      segments_count = (step.duration.to_f / MAX_STEP_DURATION).ceil
      dur = step.duration / segments_count
      dist = step.distance / segments_count
      segments_count.times.map do |index|
        build_segmented_step(step, segments_count, index, dur, dist)
      end
    end

    def self.build_segmented_step(step, count, index, dur, dist)
      is_last = index == count - 1
      seg_dur = is_last ? step.duration - (dur * index) : dur
      seg_dist = is_last ? step.distance - (dist * index) : dist
      build_segment(step, index.to_f / count, (index + 1).to_f / count, seg_dur, seg_dist)
    end

    def self.build_segment(step, f_start, f_end, dur, dist)
      RouteStep.new(
        start_lat: interpolate(step.start_lat, step.end_lat, f_start),
        start_lng: interpolate(step.start_lng, step.end_lng, f_start),
        end_lat: interpolate(step.start_lat, step.end_lat, f_end),
        end_lng: interpolate(step.start_lng, step.end_lng, f_end),
        duration: dur, distance: dist
      )
    end

    def self.interpolate(start_val, end_val, fraction)
      start_val + ((end_val - start_val) * fraction)
    end

    def self.accumulate_exposure(processed_steps, departure_time, include_steps)
      state = init_exposure_state
      processed_steps.each { |s| process_single_step(state, s, departure_time, include_steps) }
      format_exposure_result(state, processed_steps.size)
    end

    def self.process_single_step(state, step, departure_time, include_steps)
      analysis = StepAnalyzerService.analyze(
        route_step: step, trip_start_time: departure_time,
        accumulated_duration_seconds: state[:accumulated]
      )
      update_exposure(state, step, analysis)
      state[:steps] << build_step_detail(step, analysis) if include_steps
      state[:accumulated] += step.duration
    end

    def self.init_exposure_state
      { left: 0, right: 0, night: 0, front_behind: 0, accumulated: 0, night_steps: 0, steps: [] }
    end

    def self.update_exposure(state, step, analysis)
      if analysis[:sun_position].elevation <= 0.0
        state[:night_steps] += 1
        state[:night] += step.duration
      else
        case analysis[:sun_side]
        when :left then state[:left] += step.duration
        when :right then state[:right] += step.duration
        when :front, :behind then state[:front_behind] += step.duration
        end
      end
    end

    def self.build_step_detail(step, analysis)
      sun = analysis[:sun_position]
      { start_lat: step.start_lat, start_lng: step.start_lng,
        end_lat: step.end_lat, end_lng: step.end_lng,
        duration: step.duration, distance: step.distance,
        midpoint_lat: analysis[:midpoint_lat], midpoint_lng: analysis[:midpoint_lng],
        midpoint_time: analysis[:midpoint_time].iso8601, bearing: analysis[:bearing],
        sun_azimuth: sun.azimuth, sun_elevation: sun.elevation, sun_side: analysis[:sun_side].to_s }
    end

    def self.format_exposure_result(state, total_steps)
      {
        left_exposure_seconds: state[:left],
        right_exposure_seconds: state[:right],
        night_exposure_seconds: state[:night],
        front_behind_exposure_seconds: state[:front_behind],
        is_entirely_night: (state[:night_steps] == total_steps),
        steps: state[:steps]
      }
    end

    private_class_method :subdivide_steps, :subdivide_step, :build_segmented_step,
                         :build_segment, :interpolate, :accumulate_exposure,
                         :process_single_step, :init_exposure_state, :update_exposure,
                         :build_step_detail, :format_exposure_result
  end
end
