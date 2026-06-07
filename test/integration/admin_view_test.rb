require_relative '../test_helper'
require 'base64'

class AdminViewTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
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
    assert_includes last_response.body, 'ShadowMe - A True Travelmate'
    assert_includes last_response.body, 'key=test-api-key'
  end
end
