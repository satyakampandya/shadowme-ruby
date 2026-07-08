require 'zeitwerk'
require 'faraday'
require 'oj'
require 'dry-validation'
require 'sun_calc'
require 'time'

# Setup Zeitwerk autoloader for the ShadowMe gem namespace
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('shadowme' => 'ShadowMe')

# Ignore the shadowme-ruby.rb compatibility file in Zeitwerk autoloader
loader.ignore("#{__dir__}/shadowme-ruby.rb")

# Collapse subdirectories so their contents are namespaced directly under ShadowMe
# (e.g. ShadowMe::GoogleMapsClient instead of ShadowMe::Clients::GoogleMapsClient)
loader.collapse("#{__dir__}/shadowme/clients")
loader.collapse("#{__dir__}/shadowme/errors")
loader.collapse("#{__dir__}/shadowme/models")
loader.collapse("#{__dir__}/shadowme/serializers")
loader.collapse("#{__dir__}/shadowme/services")
loader.collapse("#{__dir__}/shadowme/validators")

loader.setup

module ShadowMe
  class << self
    attr_accessor :loader, :api_key

    def configure
      yield self
    end

    def eager_load!
      loader&.eager_load
    end

    # Public calculation entrypoint
    # source: "lat,lng" string
    # destination: "lat,lng" string
    # departure_time: String or Time object
    # route_index: Integer (default 0)
    # include_steps: Boolean (default false)
    #
    # Returns: Hash matching the API response structure
    # Raises: ValidationError, InvalidRouteError, GoogleApiError, SunCalculationError
    def calculate(source, destination, departure_time, route_index: nil, include_steps: nil)
      result = validate_input(source, destination, departure_time, route_index, include_steps)
      request = build_trip_request(result)
      recommendation = TripAnalyzerService.new.analyze(request)
      RecommendationSerializer.to_hash(recommendation, include_steps: result[:include_steps] == true)
    end

    private

    def validate_input(source, destination, departure_time, route_index, include_steps)
      input = { source: source, destination: destination, departure_time: departure_time.to_s }
      input[:route_index] = route_index unless route_index.nil?
      input[:include_steps] = include_steps unless include_steps.nil?

      result = RecommendationValidator.new.call(input)
      raise ValidationError.new('Validation failed', result.errors.to_h) unless result.success?

      result
    end

    def build_trip_request(result)
      TripRequest.new(
        source: result[:source],
        destination: result[:destination],
        departure_time: Time.parse(result[:departure_time]),
        route_index: result[:route_index] || 0,
        include_steps: result[:include_steps] == true
      )
    end
  end
end

ShadowMe.loader = loader
