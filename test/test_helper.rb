ENV['RACK_ENV'] = 'test'

# Ensure we use test API keys in tests
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
