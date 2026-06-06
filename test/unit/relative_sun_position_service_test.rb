require_relative '../test_helper'

class RelativeSunPositionServiceTest < Minitest::Test
  def test_identifies_sun_directly_in_front
    assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 90.0)
    assert_equal :front, RelativeSunPositionService.calculate(vehicle_bearing: 359.9999999999, sun_azimuth: 0.0)
  end

  def test_identifies_sun_directly_behind
    assert_equal :behind, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 270.0)
    assert_equal :behind, RelativeSunPositionService.calculate(vehicle_bearing: 0.0, sun_azimuth: 180.0)
  end

  def test_identifies_sun_on_right_side
    # Delta = (150 - 90) % 360 = 60 => right
    assert_equal :right, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 150.0)
    # Delta = (269.9 - 90) % 360 = 179.9 => right
    assert_equal :right, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 269.9)
  end

  def test_identifies_sun_on_left_side
    # Delta = (30 - 90) % 360 = 300 => left
    assert_equal :left, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 30.0)
    # Delta = (270.1 - 90) % 360 = 180.1 => left
    assert_equal :left, RelativeSunPositionService.calculate(vehicle_bearing: 90.0, sun_azimuth: 270.1)
  end
end
