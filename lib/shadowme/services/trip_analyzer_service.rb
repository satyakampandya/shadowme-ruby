module ShadowMe
  class TripAnalyzerService
    def initialize(google_maps_client: GoogleMapsClient.new)
      @client = google_maps_client
    end

    # Analyzes a trip request and returns a SeatRecommendation.
    # trip_request: TripRequest model
    # Returns: SeatRecommendation model
    def analyze(trip_request)
      # 1. Fetch directions from Google Maps
      directions_data = @client.directions(
        origin: trip_request.source,
        destination: trip_request.destination,
        departure_time: trip_request.departure_time
      )

      # 2. Extract RouteStep models from Google Directions data
      steps = self.class.extract_steps(directions_data, trip_request.route_index)

      # 3. Analyze route steps and accumulate exposure
      exposure = RouteAnalyzerService.analyze(
        steps: steps,
        departure_time: trip_request.departure_time,
        include_steps: trip_request.include_steps
      )

      # 4. Generate final recommendation
      SeatRecommendationService.recommend(
        left_exposure_seconds: exposure[:left_exposure_seconds],
        right_exposure_seconds: exposure[:right_exposure_seconds],
        night_exposure_seconds: exposure[:night_exposure_seconds],
        front_behind_exposure_seconds: exposure[:front_behind_exposure_seconds],
        is_entirely_night: exposure[:is_entirely_night],
        steps: exposure[:steps],
        route_index: trip_request.route_index
      )
    end

    # Extractor helper to map Google Maps JSON output structure to our RouteStep models.
    # Delegates to GoogleDirectionsRouteMapper.
    def self.extract_steps(data, route_index = 0)
      GoogleDirectionsRouteMapper.map_to_steps(data, route_index)
    end
  end
end
