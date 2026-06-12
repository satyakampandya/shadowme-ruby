require_relative '../test_helper'

module ShadowMe
  class TripAnalyzerServiceTest < Minitest::Test
    def setup
      @client = GoogleMapsClient.new(api_key: 'test-api-key')
      @analyzer = TripAnalyzerService.new(google_maps_client: @client)
    end

    def test_analyzes_trip_successfully
      departure_time = Time.parse('2026-06-10T08:00:00+05:30')

      mock_response = {
        status: 'OK',
        routes: [
          {
            legs: [
              {
                steps: [
                  {
                    distance: { value: 10_000 },
                    duration: { value: 1800 }, # 30 minutes
                    # Surat and Ahmedabad coordinates ensure daytime sun elevation at 08:00 AM local time
                    start_location: { lat: 21.17, lng: 72.83 },
                    end_location: { lat: 23.02, lng: 72.57 }
                  }
                ]
              }
            ]
          }
        ]
      }

      stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
        .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                       key: 'test-api-key', departure_time: departure_time.to_i.to_s })
        .to_return(status: 200, body: Oj.dump(mock_response,
                                              mode: :compat), headers: { 'Content-Type' => 'application/json' })

      trip_request = TripRequest.new(
        source: '21.1702,72.8311',
        destination: '23.0225,72.5714',
        departure_time: departure_time
      )

      rec = @analyzer.analyze(trip_request)

      assert_instance_of SeatRecommendation, rec
      assert_includes %w[left right], rec.recommended_side
      assert_operator rec.left_exposure_minutes, :>=, 0
      assert_operator rec.right_exposure_minutes, :>=, 0
      assert_includes %w[low medium high], rec.confidence
    end

    def test_extract_steps_splits_curved_polyline
      mock_response = {
        status: 'OK',
        routes: [
          {
            legs: [
              {
                steps: [
                  {
                    distance: { value: 10_000 },
                    duration: { value: 1800 },
                    start_location: { lat: 21.17, lng: 72.83 },
                    end_location: { lat: 21.18, lng: 72.86 },
                    polyline: { points: 'mocked_polyline_string' }
                  }
                ]
              }
            ]
          }
        ]
      }

      class << PolylineDecoder
        alias_method :original_decode, :decode
        remove_method :decode
      end
      PolylineDecoder.define_singleton_method(:decode) { |_str| [[21.17, 72.83], [21.18, 72.84], [21.18, 72.86]] }

      begin
        steps = TripAnalyzerService.extract_steps(mock_response)

        assert_equal 2, steps.size

        # Segment 1 (Heading NE ~45 deg)
        assert_in_delta 21.17, steps[0].start_lat
        assert_in_delta 72.83, steps[0].start_lng
        assert_in_delta 21.18, steps[0].end_lat
        assert_in_delta 72.84, steps[0].end_lng

        # Segment 2 (Heading E ~90 deg)
        assert_in_delta 21.18, steps[1].start_lat
        assert_in_delta 72.84, steps[1].start_lng
        assert_in_delta 21.18, steps[1].end_lat
        assert_in_delta 72.86, steps[1].end_lng
      ensure
        class << PolylineDecoder
          remove_method :decode
          alias_method :decode, :original_decode
          remove_method :original_decode
        end
      end
    end

    def test_extract_steps_raises_invalid_route_error_on_invalid_route_index
      mock_response = {
        status: 'OK',
        routes: [
          {
            legs: [
              {
                steps: [
                  {
                    distance: { value: 1000 },
                    duration: { value: 600 },
                    start_location: { lat: 21.17, lng: 72.83 },
                    end_location: { lat: 21.18, lng: 72.84 }
                  }
                ]
              }
            ]
          }
        ]
      }

      assert_raises InvalidRouteError do
        TripAnalyzerService.extract_steps(mock_response, 1)
      end
    end
  end
end
