require 'faraday'
require 'oj'

module ShadowMe
  class GoogleMapsClient
    BASE_URL = 'https://maps.googleapis.com'.freeze

    def initialize(api_key: ShadowMe.api_key || ENV.fetch('GOOGLE_MAPS_API_KEY', nil))
      @api_key = api_key
    end

    # Fetches directions from Google Directions API.
    def directions(origin:, destination:, departure_time: nil)
      validate_api_key!
      conn = build_connection
      params = build_params(origin, destination, departure_time)
      response = execute_request(conn, params)
      data = parse_response(response)
      handle_response_status(data, origin, destination)
    end

    private

    def validate_api_key!
      return unless @api_key.nil? || @api_key.empty?

      raise GoogleApiError,
            'Google Maps API key is not configured. Please set GOOGLE_MAPS_API_KEY environment variable ' \
            'or configure it via ShadowMe.api_key.'
    end

    def build_connection
      Faraday.new(url: BASE_URL) do |builder|
        builder.options.timeout = 5       # Read timeout in seconds
        builder.options.open_timeout = 2  # Connection timeout in seconds
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      end
    end

    def build_params(origin, destination, departure_time)
      params = { origin: origin, destination: destination, alternatives: 'true', key: @api_key }
      params[:departure_time] = departure_time.to_i if departure_time
      params
    end

    def execute_request(conn, params, retries = 0)
      res = conn.get('/maps/api/directions/json', params)
      raise GoogleApiError, "Google Maps API returned HTTP status #{res.status}" unless res.success?

      res
    rescue Faraday::Error => e
      raise GoogleApiError, "Failed to connect to Google Maps API: #{e.message}" if retries >= 2

      sleep(0.1 * (retries + 1))
      execute_request(conn, params, retries + 1)
    end

    def parse_response(response)
      Oj.load(response.body, symbol_keys: true)
    rescue StandardError => e
      raise GoogleApiError, "Failed to parse Google Maps API response: #{e.message}"
    end

    def handle_response_status(data, origin, destination)
      case data[:status]
      when 'OK' then data
      when 'ZERO_RESULTS', 'NOT_FOUND'
        raise InvalidRouteError, "No route found between '#{origin}' and '#{destination}'"
      when 'MAX_ROUTE_LENGTH_EXCEEDED'
        raise InvalidRouteError, "The requested route between '#{origin}' and " \
                                 "'#{destination}' is too long to be calculated."
      else
        raise_api_error(data)
      end
    end

    def raise_api_error(data)
      case data[:status]
      when 'OVER_QUERY_LIMIT', 'REQUEST_DENIED', 'INVALID_REQUEST', 'UNKNOWN_ERROR'
        raise GoogleApiError, "Google Maps API error: #{data[:error_message] || data[:status]}"
      else
        raise GoogleApiError, "Google Maps API returned unexpected status: #{data[:status]}"
      end
    end
  end
end
