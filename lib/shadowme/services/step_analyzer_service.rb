module ShadowMe
  class StepAnalyzerService
    # Analyzes a single RouteStep.
    # route_step: RouteStep instance
    # trip_start_time: Time object representing the departure time
    # accumulated_duration_seconds: time elapsed in seconds from departure to the start of this step
    # Returns a Hash containing sun_side, bearing, and midpoint metadata.
    def self.analyze(route_step:, trip_start_time:, accumulated_duration_seconds:)
      midpoint = calculate_midpoint(route_step, trip_start_time, accumulated_duration_seconds)
      bearing = calculate_bearing(route_step)

      sun_pos = SunPositionService.calculate(
        latitude: midpoint[:lat], longitude: midpoint[:lng], datetime: midpoint[:time]
      )
      sun_side = RelativeSunPositionService.calculate(vehicle_bearing: bearing, sun_azimuth: sun_pos.azimuth)

      build_analysis_hash(sun_side, sun_pos, bearing, midpoint)
    end

    def self.calculate_midpoint(step, trip_start_time, accumulated_seconds)
      lat, lng = MidpointCalculator.calculate(step.start_lat, step.start_lng, step.end_lat, step.end_lng)
      time = trip_start_time + accumulated_seconds + (step.duration / 2.0)
      { lat: lat, lng: lng, time: time }
    end

    def self.calculate_bearing(step)
      BearingCalculator.calculate(step.start_lat, step.start_lng, step.end_lat, step.end_lng)
    end

    def self.build_analysis_hash(sun_side, sun_pos, bearing, midpoint)
      { sun_side: sun_side, sun_position: sun_pos, bearing: bearing,
        midpoint_lat: midpoint[:lat], midpoint_lng: midpoint[:lng], midpoint_time: midpoint[:time] }
    end

    private_class_method :calculate_midpoint, :calculate_bearing, :build_analysis_hash
  end
end
