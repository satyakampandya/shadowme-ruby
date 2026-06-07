require_relative '../test_helper'
require 'base64'

class ApiEndpointsTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def with_stubbed_redis(client)
    # Dynamically override the class method on TripCache without redefinition warnings
    TripCache.singleton_class.send(:remove_method, :redis_client) if TripCache.respond_to?(:redis_client)
    TripCache.define_singleton_method(:redis_client) { client }
    yield
  ensure
    # Restore the default mocked nil behavior
    TripCache.singleton_class.send(:remove_method, :redis_client) if TripCache.respond_to?(:redis_client)
    TripCache.define_singleton_method(:redis_client) { nil }
  end

  def test_health_endpoint
    get '/health'

    assert last_response.ok?
    body = Oj.load(last_response.body, symbol_keys: true)
    assert_equal "ok", body[:status]
  end

  def test_readiness_endpoint_configured
    with_stubbed_redis(Object.new) do
      get '/ready'

      assert_equal 200, last_response.status
      body = Oj.load(last_response.body, symbol_keys: true)
      assert_equal "ready", body[:status]
    end
  end

  def test_readiness_endpoint_failing_when_redis_is_missing
    # redis_client is nil by default in test_helper
    get '/ready'

    assert_equal 503, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)
    assert_equal "not_ready", body[:status]
    assert_equal "failed", body[:checks][:redis]
  end

  def test_readiness_endpoint_failing_when_api_key_is_missing
    original_key = ENV['GOOGLE_MAPS_API_KEY']
    ENV['GOOGLE_MAPS_API_KEY'] = nil

    with_stubbed_redis(Object.new) do
      get '/ready'

      assert_equal 503, last_response.status
      body = Oj.load(last_response.body, symbol_keys: true)
      assert_equal "not_ready", body[:status]
      assert_equal "missing", body[:checks][:google_api]
      assert_equal "ok", body[:checks][:redis]
    end
  ensure
    ENV['GOOGLE_MAPS_API_KEY'] = original_key
  end

  def test_recommendation_endpoint_success
    payload = {
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30"
    }

    mock_response = {
      status: "OK",
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

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)
    
    assert_includes ["left", "right"], body[:recommended_side]
    assert_kind_of Integer, body[:left_exposure_minutes]
    assert_kind_of Integer, body[:right_exposure_minutes]
    assert_includes ["low", "medium", "high"], body[:confidence]
    assert_equal "You should sit on the #{body[:recommended_side]} side of the vehicle to minimize direct sunlight exposure.", body[:message]
    
    assert_kind_of Array, body[:steps]
    refute_empty body[:steps]
    step_detail = body[:steps].first
    assert_kind_of Float, step_detail[:start_lat]
  end

  def test_recommendation_endpoint_validation_errors
    payload = {
      source: "",
      destination: "23.0225,72.5714",
      departure_time: "not-a-timestamp"
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
      source: "21.1702,72.8311",
      destination: "0.0,0.0",
      departure_time: "2026-06-10T08:00:00+05:30"
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '0.0,0.0', key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump({ status: "ZERO_RESULTS", routes: [] }, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 422, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_match(/No route found/, body[:error])
  end

  def test_recommendation_endpoint_google_api_denied
    payload = {
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30"
    }

    dep_time_secs = Time.parse(payload[:departure_time]).to_i.to_s

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump({ status: "REQUEST_DENIED", error_message: "IP blocked" }, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 502, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_match(/Google Maps API error/, body[:error])
  end

  def test_recommendation_endpoint_cache_hit
    payload = {
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30"
    }

    cached_response = {
      recommended_side: "right",
      left_exposure_minutes: 40,
      right_exposure_minutes: 10,
      confidence: "high"
    }

    mock_redis = Object.new
    mock_redis.define_singleton_method(:get) { |_k| Oj.dump(cached_response, mode: :compat) }

    with_stubbed_redis(mock_redis) do
      header 'Content-Type', 'application/json'
      post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

      assert_equal 200, last_response.status
      body = Oj.load(last_response.body, symbol_keys: true)

      assert_equal "right", body[:recommended_side]
      assert_equal 40, body[:left_exposure_minutes]
      assert_equal 10, body[:right_exposure_minutes]
      assert_equal "high", body[:confidence]
    end
  end

  def test_recommendation_endpoint_entirely_night
    payload = {
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T23:00:00+05:30"
    }

    mock_response = {
      status: "OK",
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

    stub_request(:get, "https://maps.googleapis.com/maps/api/directions/json")
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', key: 'test-api-key', departure_time: dep_time_secs })
      .to_return(status: 200, body: Oj.dump(mock_response, mode: :compat), headers: { 'Content-Type' => 'application/json' })

    header 'Content-Type', 'application/json'
    post '/api/v1/recommendation', Oj.dump(payload, mode: :compat)

    assert_equal 200, last_response.status
    body = Oj.load(last_response.body, symbol_keys: true)

    assert_equal "either", body[:recommended_side]
    assert_equal 0, body[:left_exposure_minutes]
    assert_equal 0, body[:right_exposure_minutes]
    assert_equal "high", body[:confidence]
    assert_equal "It is night time, enjoy your journey!", body[:message]
  end

  def test_admin_endpoint_unauthorized
    get '/admin'
    assert_equal 401, last_response.status
    assert_equal 'Basic realm="ShadowMe Admin UI"', last_response.headers['WWW-Authenticate']
    assert_equal 'Unauthorized', last_response.body
  end

  def test_admin_endpoint_authorized
    # Encode 'admin:admin123' in Base64
    credentials = Base64.strict_encode64('admin:admin123')
    header 'Authorization', "Basic #{credentials}"
    
    get '/admin'
    assert_equal 200, last_response.status
    assert_includes last_response.headers['Content-Type'], 'text/html'
    assert_includes last_response.body, 'ShadowMe Admin Portal'
    assert_includes last_response.body, 'key=test-api-key'
  end
end
