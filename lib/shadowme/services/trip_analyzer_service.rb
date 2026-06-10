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
    # Subdivides steps using encoded polylines to detect curves and merges straight segments.
    def self.extract_steps(data, route_index = 0)
      routes = data[:routes]
      raise InvalidRouteError, 'Google Directions response did not contain any routes' if routes.nil? || routes.empty?

      steps = []
      # Analyze the requested route (fallback to index 0 if out of bounds)
      selected_route = routes[route_index] || routes[0]
      legs = selected_route[:legs] || []

      legs.each do |leg|
        leg_steps = leg[:steps] || []
        leg_steps.each do |step_data|
          # Validate that all required properties exist
          unless step_data[:start_location] && step_data[:end_location] && step_data[:duration] && step_data[:distance]
            next
          end

          # Try decoding polyline for curve detection
          encoded_points = step_data[:polyline] && step_data[:polyline][:points]
          points = encoded_points ? PolylineDecoder.decode(encoded_points) : []

          if points.size < 2
            steps << RouteStep.new(
              start_lat: step_data[:start_location][:lat],
              start_lng: step_data[:start_location][:lng],
              end_lat: step_data[:end_location][:lat],
              end_lng: step_data[:end_location][:lng],
              duration: step_data[:duration][:value],
              distance: step_data[:distance][:value]
            )
            next
          end

          # Compute raw segments from decoded polyline points
          raw_segments = []
          total_len = 0.0

          (points.size - 1).times do |i|
            lat1, lng1 = points[i]
            lat2, lng2 = points[i + 1]

            d_lat = lat2 - lat1
            d_lng = lng2 - lng1
            mid_lat_rad = (lat1 + lat2) / 2.0 * Math::PI / 180.0
            dx = d_lng * Math.cos(mid_lat_rad)
            len = Math.sqrt((d_lat * d_lat) + (dx * dx))

            bearing = BearingCalculator.calculate(lat1, lng1, lat2, lng2)

            raw_segments << {
              start_lat: lat1,
              start_lng: lng1,
              end_lat: lat2,
              end_lng: lng2,
              len: len,
              bearing: bearing
            }
            total_len += len
          end

          if total_len <= 0.0
            steps << RouteStep.new(
              start_lat: step_data[:start_location][:lat],
              start_lng: step_data[:start_location][:lng],
              end_lat: step_data[:end_location][:lat],
              end_lng: step_data[:end_location][:lng],
              duration: step_data[:duration][:value],
              distance: step_data[:distance][:value]
            )
            next
          end

          total_duration = step_data[:duration][:value].to_f
          total_distance = step_data[:distance][:value].to_f

          raw_segments.each do |seg|
            seg[:duration] = total_duration * (seg[:len] / total_len)
            seg[:distance] = total_distance * (seg[:len] / total_len)
          end

          # Merge consecutive segments with similar bearings (threshold = 10 degrees)
          heading_threshold = 10.0
          current_group = nil

          raw_segments.each do |seg|
            if current_group.nil?
              current_group = {
                start_lat: seg[:start_lat],
                start_lng: seg[:start_lng],
                end_lat: seg[:end_lat],
                end_lng: seg[:end_lng],
                duration: seg[:duration],
                distance: seg[:distance],
                bearing: seg[:bearing]
              }
            else
              diff = (seg[:bearing] - current_group[:bearing]).abs
              diff = 360.0 - diff if diff > 180.0

              if diff <= heading_threshold
                # Merge
                current_group[:end_lat] = seg[:end_lat]
                current_group[:end_lng] = seg[:end_lng]
                current_group[:duration] += seg[:duration]
                current_group[:distance] += seg[:distance]
              else
                # Flush group
                steps << RouteStep.new(
                  start_lat: current_group[:start_lat],
                  start_lng: current_group[:start_lng],
                  end_lat: current_group[:end_lat],
                  end_lng: current_group[:end_lng],
                  duration: current_group[:duration].round,
                  distance: current_group[:distance].round
                )

                current_group = {
                  start_lat: seg[:start_lat],
                  start_lng: seg[:start_lng],
                  end_lat: seg[:end_lat],
                  end_lng: seg[:end_lng],
                  duration: seg[:duration],
                  distance: seg[:distance],
                  bearing: seg[:bearing]
                }
              end
            end
          end

          next unless current_group

          steps << RouteStep.new(
            start_lat: current_group[:start_lat],
            start_lng: current_group[:start_lng],
            end_lat: current_group[:end_lat],
            end_lng: current_group[:end_lng],
            duration: current_group[:duration].round,
            distance: current_group[:distance].round
          )
        end
      end

      raise InvalidRouteError, 'No valid steps found in the route legs' if steps.empty?

      steps
    end
  end
end
