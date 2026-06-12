require_relative '../test_helper'

module ShadowMe
  class RelativeSunPositionServiceTest < Minitest::Test
    def test_identifies_sun_in_front_within_tolerance
      # Exactly in front (delta = 0.0)
      assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 90.0)
      # Right at the positive boundary (delta = 5.0)
      assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 95.0)
      # Right at the negative boundary (delta = 355.0)
      assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 85.0)
      # Slightly inside the positive boundary
      assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 359.99999, sun_azimuth: 0.0)
    end

    def test_identifies_sun_behind_within_tolerance
      # Exactly behind (delta = 180.0)
      assert_equal :behind, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 270.0)
      # Right at the boundary below 180 (delta = 175.0)
      assert_equal :behind, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 265.0)
      # Right at the boundary above 180 (delta = 185.0)
      assert_equal :behind, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 275.0)
    end

    def test_identifies_sun_on_right_side
      # Delta = (150 - 90) % 360 = 60 => right
      assert_equal :right, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 150.0)
      # Just outside the behind boundary (delta = 174.9)
      assert_equal :right, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 264.9)
      # Just outside the front boundary (delta = 5.1)
      assert_equal :right, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 95.1)
    end

    def test_identifies_sun_on_left_side
      # Delta = (30 - 90) % 360 = 300 => left
      assert_equal :left, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 30.0)
      # Just outside the behind boundary (delta = 185.1)
      assert_equal :left, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 275.1)
      # Just outside the front boundary (delta = 354.9)
      assert_equal :left, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 84.9)
    end
  end
end
