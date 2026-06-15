module ShadowMe
  module StepAnalyzerService
    # ponytail: simplified step analyzer combining midpoint and bearing logic
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.analyze(route_step:, trip_start_time:, accumulated_duration_seconds:)
      lat, lng = MidpointCalculator.calculate(
        route_step.start_lat, route_step.start_lng, route_step.end_lat, route_step.end_lng
      )
      time = trip_start_time + accumulated_duration_seconds + (route_step.duration / 2.0)
      bearing = BearingCalculator.calculate(
        route_step.start_lat, route_step.start_lng, route_step.end_lat, route_step.end_lng
      )
      sun_pos = SunPositionService.calculate(latitude: lat, longitude: lng, datetime: time)
      sun_side = RelativeSunPositionService.calculate(vehicle_bearing: bearing, sun_azimuth: sun_pos.azimuth)

      { sun_side: sun_side, sun_position: sun_pos, bearing: bearing,
        midpoint_lat: lat, midpoint_lng: lng, midpoint_time: time }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end
