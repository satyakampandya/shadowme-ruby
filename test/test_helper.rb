ENV['RACK_ENV'] = 'test'

# Ensure we use test API keys
ENV['GOOGLE_MAPS_API_KEY'] = 'test-api-key'

require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'
require 'rack/test'

# Set up clean output formatting (suppressed inside JetBrains/RubyMine to avoid reporter conflicts)
Minitest::Reporters.use!(Minitest::Reporters::SpecReporter.new) unless ENV['RM_INFO']

# Block all external network requests during tests
WebMock.disable_net_connect!(allow_localhost: true)

# Ensure root lib is in the load path when running tests from subdirectories
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# Require main application (loads the shadowme gem code)
require 'shadowme'

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
GoogleMapsClient = ShadowMe::GoogleMapsClient
