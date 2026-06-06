require_relative '../test_helper'

class TripAnalyzerServiceTest < Minitest::Test
  def setup
    @client = GoogleMapsClient.new(api_key: 'test-api-key')
    @analyzer = TripAnalyzerService.new(google_maps_client: @client)
  end

  def test_analyzes_trip_successfully
    departure_time = Time.parse("2026-06-10T08:00:00+05:30")

    mock_response = {
      status: "OK",
      routes: [
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 10000 },
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

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key', departure_time: departure_time.to_i.to_s })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    trip_request = TripRequest.new(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: departure_time
    )

    rec = @analyzer.analyze(trip_request)

    assert_instance_of SeatRecommendation, rec
    assert_includes ["left", "right"], rec.recommended_side
    assert_operator rec.left_exposure_minutes, :>=, 0
    assert_operator rec.right_exposure_minutes, :>=, 0
    assert_includes ["low", "medium", "high"], rec.confidence
  end
end
