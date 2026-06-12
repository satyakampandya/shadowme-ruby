require_relative '../test_helper'

module ShadowMe
  class BearingCalculatorTest < Minitest::Test
    def test_bearing_due_north
      # Straight North along a meridian
      bearing = BearingCalculator.calculate(10.0, 50.0, 20.0, 50.0)
      assert_in_delta 0.0, bearing, 0.1
    end

    def test_bearing_due_south
      # Straight South along a meridian
      bearing = BearingCalculator.calculate(20.0, 50.0, 10.0, 50.0)
      assert_in_delta 180.0, bearing, 0.1
    end

    def test_bearing_due_east_at_equator
      # Straight East along the equator
      bearing = BearingCalculator.calculate(0.0, 0.0, 0.0, 10.0)
      assert_in_delta 90.0, bearing, 0.1
    end

    def test_bearing_due_west_at_equator
      # Straight West along the equator
      bearing = BearingCalculator.calculate(0.0, 10.0, 0.0, 0.0)
      assert_in_delta 270.0, bearing, 0.1
    end
  end
end
