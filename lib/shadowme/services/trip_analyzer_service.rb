module ShadowMe
  class TripAnalyzerService
    def initialize(google_maps_client: GoogleMapsClient.new)
      @client = google_maps_client
    end

    # Analyzes a trip request and returns a SeatRecommendation.
    # trip_request: TripRequest model
    # Returns: SeatRecommendation model
    def analyze(trip_request)
      steps = fetch_and_extract_steps(trip_request)
      exposure = analyze_exposure(steps, trip_request)
      build_recommendation(exposure, trip_request.route_index)
    end

    # Extractor helper to map Google Maps JSON output structure to our RouteStep models.
    # Delegates to GoogleDirectionsRouteMapper.
    def self.extract_steps(data, route_index = 0)
      GoogleDirectionsRouteMapper.map_to_steps(data, route_index)
    end

    private

    def fetch_and_extract_steps(trip_request)
      directions_data = @client.directions(
        origin: trip_request.source,
        destination: trip_request.destination,
        departure_time: trip_request.departure_time
      )
      self.class.extract_steps(directions_data, trip_request.route_index)
    end

    def analyze_exposure(steps, trip_request)
      RouteAnalyzerService.analyze(
        steps: steps,
        departure_time: trip_request.departure_time,
        include_steps: trip_request.include_steps
      )
    end

    def build_recommendation(exposure, route_index)
      SeatRecommendationService.recommend(
        left_exposure_seconds: exposure[:left_exposure_seconds],
        right_exposure_seconds: exposure[:right_exposure_seconds],
        night_exposure_seconds: exposure[:night_exposure_seconds],
        front_behind_exposure_seconds: exposure[:front_behind_exposure_seconds],
        is_entirely_night: exposure[:is_entirely_night],
        steps: exposure[:steps],
        route_index: route_index
      )
    end
  end
end
