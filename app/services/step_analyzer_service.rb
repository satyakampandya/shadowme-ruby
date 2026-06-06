class StepAnalyzerService
  # Analyzes a single RouteStep.
  # route_step: RouteStep instance
  # trip_start_time: Time object representing the departure time
  # accumulated_duration_seconds: time elapsed in seconds from departure to the start of this step
  # Returns a Hash containing sun_side, bearing, and midpoint metadata.
  def self.analyze(route_step:, trip_start_time:, accumulated_duration_seconds:)
    # 1. Determine Step Midpoint Location
    mid_lat, mid_lng = MidpointCalculator.calculate(
      route_step.start_lat,
      route_step.start_lng,
      route_step.end_lat,
      route_step.end_lng
    )

    # 2. Determine Step Midpoint Time
    # Evaluates the sun's position at the midpoint of this step
    midpoint_offset = route_step.duration / 2.0
    midpoint_time = trip_start_time + accumulated_duration_seconds + midpoint_offset

    # 3. Determine Vehicle Bearing
    bearing = BearingCalculator.calculate(
      route_step.start_lat,
      route_step.start_lng,
      route_step.end_lat,
      route_step.end_lng
    )

    # 4. Calculate Sun Position
    sun_position = SunPositionService.calculate(
      latitude: mid_lat,
      longitude: mid_lng,
      datetime: midpoint_time
    )

    # 5. Determine Sun Side Relative to Vehicle
    sun_side = RelativeSunPositionService.calculate(
      vehicle_bearing: bearing,
      sun_azimuth: sun_position.azimuth
    )

    {
      sun_side: sun_side,
      sun_position: sun_position,
      bearing: bearing,
      midpoint_lat: mid_lat,
      midpoint_lng: mid_lng,
      midpoint_time: midpoint_time
    }
  end
end
