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
    steps = self.class.extract_steps(directions_data)

    # 3. Analyze route steps and accumulate exposure
    exposure = RouteAnalyzerService.analyze(
      steps: steps,
      departure_time: trip_request.departure_time
    )

    # 4. Generate final recommendation
    SeatRecommendationService.recommend(
      left_exposure_seconds: exposure[:left_exposure_seconds],
      right_exposure_seconds: exposure[:right_exposure_seconds],
      is_entirely_night: exposure[:is_entirely_night]
    )
  end

  # Extractor helper to map Google Maps JSON output structure to our RouteStep models.
  def self.extract_steps(data)
    routes = data[:routes]
    if routes.nil? || routes.empty?
      raise InvalidRouteError, "Google Directions response did not contain any routes"
    end

    steps = []
    # Analyze the primary/first route returned
    primary_route = routes[0]
    legs = primary_route[:legs] || []

    legs.each do |leg|
      leg_steps = leg[:steps] || []
      leg_steps.each do |step_data|
        # Validate that all required properties exist
        unless step_data[:start_location] && step_data[:end_location] && step_data[:duration] && step_data[:distance]
          next
        end

        steps << RouteStep.new(
          start_lat: step_data[:start_location][:lat],
          start_lng: step_data[:start_location][:lng],
          end_lat: step_data[:end_location][:lat],
          end_lng: step_data[:end_location][:lng],
          duration: step_data[:duration][:value],
          distance: step_data[:distance][:value]
        )
      end
    end

    if steps.empty?
      raise InvalidRouteError, "No valid steps found in the route legs"
    end

    steps
  end
end
