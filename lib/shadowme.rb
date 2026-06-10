require 'zeitwerk'
require 'faraday'
require 'oj'
require 'dry-validation'
require 'sun_calc'
require 'time'

# Setup Zeitwerk autoloader for the ShadowMe gem namespace
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect("shadowme" => "ShadowMe")

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
  # Public calculation entrypoint
  # source: "lat,lng" string
  # destination: "lat,lng" string
  # departure_time: String or Time object
  # route_index: Integer (default 0)
  # include_steps: Boolean (default false)
  #
  # Returns: Hash matching the API response structure
  # Raises: ValidationError, InvalidRouteError, GoogleApiError, SunCalculationError
  def self.calculate(source, destination, departure_time, route_index: 0, include_steps: false)
    # 1. Input Validation
    validator = RecommendationValidator.new
    validation_result = validator.call(
      source: source,
      destination: destination,
      departure_time: departure_time.to_s,
      route_index: route_index,
      include_steps: include_steps
    )

    unless validation_result.success?
      raise ValidationError.new("Validation failed", validation_result.errors.to_h)
    end

    # 2. Time Parsing
    parsed_time = departure_time.is_a?(Time) ? departure_time : Time.parse(departure_time.to_s)

    # 3. Build Model & Analyze
    trip_request = TripRequest.new(
      source: source,
      destination: destination,
      departure_time: parsed_time,
      route_index: route_index,
      include_steps: include_steps
    )

    analyzer = TripAnalyzerService.new
    recommendation = analyzer.analyze(trip_request)

    # 4. Serialize to Hash
    RecommendationSerializer.to_hash(recommendation, include_steps: include_steps)
  end
end
