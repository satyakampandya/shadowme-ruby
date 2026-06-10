ENV['RACK_ENV'] = 'test'

# Ensure we use test API keys
ENV['GOOGLE_MAPS_API_KEY'] = 'test-api-key'

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'
require 'rack/test'

# Set up clean output formatting
Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new)

# Block all external network requests during tests
WebMock.disable_net_connect!(allow_localhost: true)

# Require main application (which loads the shadowme gem code)
require_relative '../app'

# Alias namespaced constants to global namespace for test suite compatibility
ValidationError = ShadowMe::ValidationError
InvalidRouteError = ShadowMe::InvalidRouteError
GoogleApiError = ShadowMe::GoogleApiError
SunCalculationError = ShadowMe::SunCalculationError
RouteStep = ShadowMe::RouteStep
SeatRecommendation = ShadowMe::SeatRecommendation
SunPosition = ShadowMe::SunPosition
TripRequest = ShadowMe::TripRequest
BearingCalculator = ShadowMe::BearingCalculator
MidpointCalculator = ShadowMe::MidpointCalculator
PolylineDecoder = ShadowMe::PolylineDecoder
RelativeSunPositionService = ShadowMe::RelativeSunPositionService
RouteAnalyzerService = ShadowMe::RouteAnalyzerService
SeatRecommendationService = ShadowMe::SeatRecommendationService
StepAnalyzerService = ShadowMe::StepAnalyzerService
SunPositionService = ShadowMe::SunPositionService
TripAnalyzerService = ShadowMe::TripAnalyzerService
AdminView = ShadowMe::AdminView
GoogleMapsClient = ShadowMe::GoogleMapsClient
