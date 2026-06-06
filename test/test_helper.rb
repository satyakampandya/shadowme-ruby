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

# Require main application
require_relative '../app'

# Mock TripCache Redis connection by default to make tests self-contained
class TripCache
  singleton_class.send(:remove_method, :redis_client) if respond_to?(:redis_client)
  def self.redis_client
    nil
  end
end
