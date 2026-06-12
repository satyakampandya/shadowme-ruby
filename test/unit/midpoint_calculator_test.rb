require_relative '../test_helper'

module ShadowMe
  class MidpointCalculatorTest < Minitest::Test
    def test_calculates_correct_midpoint
      lat1 = 12.0
      lng1 = 77.0
      lat2 = 13.0
      lng2 = 78.0

      mid_lat, mid_lng = MidpointCalculator.calculate(lat1, lng1, lat2, lng2)

      assert_in_delta 12.5, mid_lat, 1e-9
      assert_in_delta 77.5, mid_lng, 1e-9
    end

    def test_calculates_midpoint_with_negatives
      lat1 = -10.5
      lng1 = -40.2
      lat2 = -5.5
      lng2 = -20.2

      mid_lat, mid_lng = MidpointCalculator.calculate(lat1, lng1, lat2, lng2)

      assert_in_delta(-8.0, mid_lat, 1e-9)
      assert_in_delta(-30.2, mid_lng, 1e-9)
    end
  end
end
