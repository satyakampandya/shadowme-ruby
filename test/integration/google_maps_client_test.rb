require_relative '../test_helper'

class GoogleMapsClientTest < Minitest::Test
  def setup
    @client = GoogleMapsClient.new(api_key: 'test-api-key')
  end

  def test_fetches_directions_successfully
    mock_response = {
      status: "OK",
      routes: [
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 5000 },
                  duration: { value: 600 },
                  start_location: { lat: 21.17, lng: 72.83 },
                  end_location: { lat: 21.20, lng: 72.85 }
                }
              ]
            }
          ]
        }
      ]
    }

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key' })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    result = @client.directions(origin: '21.1702,72.8311', destination: '23.0225,72.5714')

    assert_equal 'OK', result[:status]
    assert_equal 1, result[:routes].size
  end

  def test_raises_invalid_route_error_on_zero_results
    mock_response = {
      status: "ZERO_RESULTS",
      routes: []
    }

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '0.0,0.0', key: 'test-api-key' })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    assert_raises InvalidRouteError do
      @client.directions(origin: '21.1702,72.8311', destination: '0.0,0.0')
    end
  end

  def test_raises_google_api_error_on_denied_access
    mock_response = {
      status: "REQUEST_DENIED",
      error_message: "The provided API key is invalid."
    }

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key' })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    exception = assert_raises GoogleApiError do
      @client.directions(origin: '21.1702,72.8311', destination: '23.0225,72.5714')
    end
    assert_match(/Google Maps API error: The provided API key is invalid/, exception.message)
  end
end
