require_relative '../test_helper'

module ShadowMe
  class GoogleDirectionsRouteMapperTest < Minitest::Test
    def test_map_to_steps_raises_on_empty_routes
      assert_raises InvalidRouteError do
        GoogleDirectionsRouteMapper.map_to_steps({ routes: [] }, 0)
      end
    end

    def test_map_to_steps_raises_on_nil_routes
      assert_raises InvalidRouteError do
        GoogleDirectionsRouteMapper.map_to_steps({ routes: nil }, 0)
      end
    end

    def test_map_to_steps_raises_on_out_of_bounds_route_index
      mock_data = {
        routes: [
          { legs: [] }
        ]
      }
      assert_raises InvalidRouteError do
        GoogleDirectionsRouteMapper.map_to_steps(mock_data, 1)
      end
      assert_raises InvalidRouteError do
        GoogleDirectionsRouteMapper.map_to_steps(mock_data, -1)
      end
    end

    def test_map_to_steps_success
      mock_data = {
        routes: [
          {
            legs: [
              {
                steps: [
                  {
                    distance: { value: 100 },
                    duration: { value: 10 },
                    start_location: { lat: 10.0, lng: 20.0 },
                    end_location: { lat: 10.1, lng: 20.1 }
                  }
                ]
              }
            ]
          }
        ]
      }
      steps = GoogleDirectionsRouteMapper.map_to_steps(mock_data, 0)
      assert_equal 1, steps.size
      assert_equal 10.0, steps.first.start_lat
      assert_equal 10.1, steps.first.end_lat
    end
  end
end
