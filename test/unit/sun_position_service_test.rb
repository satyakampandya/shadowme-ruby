require_relative '../test_helper'

class SunPositionServiceTest < Minitest::Test
  def test_calculates_sun_position_successfully
    # Surat coordinates
    lat = 21.1702
    lng = 72.8311
    time = Time.parse("2026-06-10T08:00:00+05:30")

    result = SunPositionService.calculate(latitude: lat, longitude: lng, datetime: time)

    assert_instance_of SunPosition, result
    assert_kind_of Float, result.azimuth
    assert_kind_of Float, result.elevation
    assert_operator result.azimuth, :>=, 0.0
    assert_operator result.azimuth, :<, 360.0
  end

  def test_handles_string_datetime_inputs
    lat = 21.1702
    lng = 72.8311
    time_str = "2026-06-10T08:00:00+05:30"

    result = SunPositionService.calculate(latitude: lat, longitude: lng, datetime: time_str)
    assert_instance_of SunPosition, result
  end

  def test_raises_sun_calculation_error_on_invalid_datetime
    assert_raises SunCalculationError do
      SunPositionService.calculate(latitude: 21.1702, longitude: 72.8311, datetime: "bad-format")
    end
  end
end
