require 'zeitwerk'
require 'faraday'
require 'oj'
require 'dry-validation'
require 'sun_calc'
require 'time'

# Setup Zeitwerk autoloader for the ShadowMe gem namespace
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('shadowme' => 'ShadowMe')

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
    attr_accessor :loader
  end

  def self.eager_load!
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
  def self.calculate(source, destination, departure_time, route_index: nil, include_steps: nil)
    # 1. Input Validation (filter nil inputs so dry-validation rules apply correctly)
    validation_input = {
      source: source,
      destination: destination,
      departure_time: departure_time.to_s
    }
    validation_input[:route_index] = route_index unless route_index.nil?
    validation_input[:include_steps] = include_steps unless include_steps.nil?

    validator = RecommendationValidator.new
    validation_result = validator.call(validation_input)

    raise ValidationError.new('Validation failed', validation_result.errors.to_h) unless validation_result.success?

    # 2. Extract validated / coerced outputs
    coerced_source = validation_result[:source]
    coerced_destination = validation_result[:destination]
    coerced_departure_time_str = validation_result[:departure_time]
    coerced_route_index = validation_result[:route_index] || 0
    coerced_include_steps = validation_result[:include_steps] == true

    # 3. Time Parsing
    parsed_time = Time.parse(coerced_departure_time_str)

    # 4. Build Model & Analyze
    trip_request = TripRequest.new(
      source: coerced_source,
      destination: coerced_destination,
      departure_time: parsed_time,
      route_index: coerced_route_index,
      include_steps: coerced_include_steps
    )

    analyzer = TripAnalyzerService.new
    recommendation = analyzer.analyze(trip_request)

    # 5. Serialize to Hash
    RecommendationSerializer.to_hash(recommendation, include_steps: coerced_include_steps)
  end
end

ShadowMe.loader = loader
