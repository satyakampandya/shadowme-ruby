require_relative '../../../test/test_helper'
require_relative '../app'
require 'base64'

class AdminViewTest < Minitest::Test
  include Rack::Test::Methods

  def app
    App
  end

  def test_admin_endpoint
    get '/admin'
    assert_equal 200, last_response.status
    assert_includes last_response.headers['Content-Type'], 'text/html'
    assert_includes last_response.body, 'ShadowMe - A True Travelmate'
    assert_includes last_response.body, 'key=test-api-key'
  end

  def test_static_css_asset
    get '/css/admin.css'
    assert_equal 200, last_response.status
    assert_includes last_response.headers['Content-Type'], 'text/css'
    assert_includes last_response.body, '--bg-color'
  end

  def test_static_js_asset
    get '/js/admin.js'
    assert_equal 200, last_response.status
    assert_match(/javascript/, last_response.headers['Content-Type'])
    assert_includes last_response.body, 'let map;'
  end
end
