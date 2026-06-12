require 'faraday'
require 'oj'

module ShadowMe
  class GoogleMapsClient
    BASE_URL = 'https://maps.googleapis.com'.freeze

    def initialize(api_key: ENV.fetch('GOOGLE_MAPS_API_KEY', nil))
      @api_key = api_key
    end

    # Fetches directions from Google Directions API.
    # origin: string representing starting point
    # destination: string representing endpoint
    # departure_time: optional Time object
    # Returns the parsed response hash if successful.
    # Raises GoogleApiError or InvalidRouteError on failure.
    def directions(origin:, destination:, departure_time: nil)
      if @api_key.nil? || @api_key.empty?
        raise GoogleApiError,
              'Google Maps API key is not configured. Please set GOOGLE_MAPS_API_KEY environment variable.'
      end

      conn = Faraday.new(url: BASE_URL) do |builder|
        builder.options.timeout = 5       # Read timeout in seconds
        builder.options.open_timeout = 2  # Connection timeout in seconds
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      end

      params = {
        origin: origin,
        destination: destination,
        alternatives: 'true',
        key: @api_key
      }

      params[:departure_time] = departure_time.to_i if departure_time

      max_retries = 2
      retries = 0

      begin
        response = conn.get('/maps/api/directions/json', params)
      rescue Faraday::Error => e
        raise GoogleApiError, "Failed to connect to Google Maps API: #{e.message}" unless retries < max_retries

        retries += 1
        sleep(0.1 * retries)
        retry
      end

      raise GoogleApiError, "Google Maps API returned HTTP status #{response.status}" unless response.success?

      begin
        data = Oj.load(response.body, symbol_keys: true)
      rescue StandardError => e
        raise GoogleApiError, "Failed to parse Google Maps API response: #{e.message}"
      end

      case data[:status]
      when 'OK'
        data
      when 'ZERO_RESULTS', 'NOT_FOUND'
        raise InvalidRouteError, "No route found between '#{origin}' and '#{destination}'"
      when 'MAX_ROUTE_LENGTH_EXCEEDED'
        raise InvalidRouteError,
              "The requested route between '#{origin}' and '#{destination}' is too long to be calculated."
      when 'OVER_QUERY_LIMIT', 'REQUEST_DENIED', 'INVALID_REQUEST', 'UNKNOWN_ERROR'
        error_msg = data[:error_message] || "Status: #{data[:status]}"
        raise GoogleApiError, "Google Maps API error: #{error_msg}"
      else
        raise GoogleApiError, "Google Maps API returned unexpected status: #{data[:status]}"
      end
    end
  end
end
