require_relative '../../../test/test_helper'
require_relative '../app'
require 'base64'

class ApiEndpointsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_health_endpoint
    get '/health'

    assert last_response.ok?
    body = Oj.load(last_response.body, symbol_keys: true)
    assert_equal 'ok', body[:status]
  end

  def test_readiness_endpoint_configured
    get '/ready'

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)
    assert_equal 'ready', body[:status]
    assert_equal 'configured', body[:checks][:google_api]
  end

  def test_readiness_endpoint_failing_when_api_key_is_missing
    original_key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
    ENV['GOOGLE_MAPS_API_KEY'] = nil

    begin
      get '/ready'

      assert_equal 503, last_response.status
      body = Oj.load(last_response.body, symbol_keys: true)
      assert_equal 'not_ready', body[:status]
      assert_equal 'missing', body[:checks][:google_api]
    ensure
      ENV['GOOGLE_MAPS_API_KEY'] = original_key
    end
  end

  def test_recommendation_endpoint_success
    payload = {
      source: '21.1702,72.8311',
      destination: '23.0225,72.5714',
      departure_time: '2026-06-10T08:00:00+05:30'
    }

    mock_response = {
      status: 'OK',
      routes: [
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 1500 },
                  duration: { value: 300 },
                  start_location: { lat: 21.17, lng: 72.83 },
                  end_location: { lat: 21.18, lng: 72.84 }
                }
              ]
            }
          ]
        }
      ]
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response,
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_includes %w[left right], body[:recommended_side]
    assert_kind_of Integer, body[:left_exposure_minutes]
    assert_kind_of Integer, body[:right_exposure_minutes]
    assert_kind_of Integer, body[:front_behind_exposure_minutes]
    assert_includes %w[low medium high], body[:confidence]
    expected_msg = "You should sit on the #{body[:recommended_side]} side of the vehicle " \
                   'to minimize direct sunlight exposure.'
    assert_equal expected_msg, body[:message]

    # Assert steps are excluded by default
    assert_nil body[:steps]
  end

  def test_recommendation_endpoint_includes_steps_when_requested
    dep_time_secs = Time.parse('2026-06-10T08:00:00+05:30').to_i
    mock_response = {
      status: 'OK',
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

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response,
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    payload = {
      source: '21.1702,72.8311',
      destination: '23.0225,72.5714',
      departure_time: '2026-06-10T08:00:00+05:30',
      include_steps: true
    }

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_kind_of Array, body[:steps]
    refute_empty body[:steps]
    step_detail = body[:steps].first
    assert_kind_of Float, step_detail[:start_lat]
  end

  def test_recommendation_endpoint_preflight_request
    options '/api/v1/recommendation'

    assert_equal 200, last_response.status
    assert_equal '*', last_response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, OPTIONS', last_response.headers['Access-Control-Allow-Methods']
    assert_equal 'Content-Type, Authorization, X-Requested-With', last_response.headers['Access-Control-Allow-Headers']
    assert_empty last_response.body
  end

  def test_recommendation_endpoint_validation_errors
    payload = {
      source: '',
      destination: '23.0225,72.5714',
      departure_time: 'not-a-timestamp'
    }

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 400, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_match(/Validation failed/, body[:error])
    assert_includes body[:validation_errors].keys, :source
    assert_includes body[:validation_errors].keys, :departure_time
  end

  def test_recommendation_endpoint_no_route_found
    payload = {
      source: '21.1702,72.8311',
      destination: '0.0,0.0',
      departure_time: '2026-06-10T08:00:00+05:30'
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '0.0,0.0', alternatives: 'true', key: 'test-api-key',
                     departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump({ status: 'ZERO_RESULTS', routes: [] },
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 422, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_match(/No route found/, body[:error])
  end

  def test_recommendation_endpoint_google_api_denied
    payload = {
      source: '21.1702,72.8311',
      destination: '23.0225,72.5714',
      departure_time: '2026-06-10T08:00:00+05:30'
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump({ status: 'REQUEST_DENIED', error_message: 'IP blocked' },
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 502, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_match(/Google Maps API error/, body[:error])
  end

  def test_recommendation_endpoint_entirely_night
    payload = {
      source: '21.1702,72.8311',
      destination: '23.0225,72.5714',
      departure_time: '2026-06-10T23:00:00+05:30'
    }

    mock_response = {
      status: 'OK',
      routes: [
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 1500 },
                  duration: { value: 300 },
                  start_location: { lat: 21.17, lng: 72.83 },
                  end_location: { lat: 21.18, lng: 72.84 }
                }
              ]
            }
          ]
        }
      ]
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response,
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_equal 'either', body[:recommended_side]
    assert_equal 0, body[:left_exposure_minutes]
    assert_equal 0, body[:right_exposure_minutes]
    assert_equal 5, body[:night_exposure_minutes]
    assert_equal 'high', body[:confidence]
    assert_equal 'It is night time, enjoy your journey!', body[:message]
  end

  def test_recommendation_endpoint_with_route_index_success
    payload = {
      source: '21.1702,72.8311',
      destination: '23.0225,72.5714',
      departure_time: '2026-06-10T08:00:00+05:30',
      route_index: 1
    }

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
                  end_location: { lat: 21.18, lng: 72.83 }
                }
              ]
            }
          ]
        },
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 2000 },
                  duration: { value: 1200 },
                  start_location: { lat: 21.17, lng: 72.83 },
                  end_location: { lat: 21.17, lng: 72.84 }
                }
              ]
            }
          ]
        }
      ]
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response,
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    # Route 1 has step of duration 1200 seconds = 20 minutes
    total_exposure = body[:left_exposure_minutes] + body[:right_exposure_minutes]
    assert_equal 20, total_exposure
  end
end
