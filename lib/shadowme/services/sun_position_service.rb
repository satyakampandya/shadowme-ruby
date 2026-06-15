require 'time'
require 'sun_calc'

module ShadowMe
  module SunPositionService
    # ponytail: simplified standard astronomy conversions
    def self.calculate(latitude:, longitude:, datetime:)
      time = parse_time(datetime)
      pos = SunCalc.sun_position(time, latitude.to_f, longitude.to_f)
      azimuth = (((pos[:azimuth] * 180.0) / Math::PI) + 180.0) % 360.0
      elevation = pos[:altitude] * 180.0 / Math::PI
      SunPosition.new(azimuth: azimuth, elevation: elevation)
    rescue StandardError => e
      raise SunCalculationError, "Failed to calculate sun position: #{e.message}"
    end

    def self.parse_time(datetime)
      datetime.is_a?(String) ? Time.parse(datetime) : datetime.to_time
    rescue StandardError => e
      raise SunCalculationError, "Invalid departure_time/datetime format: #{e.message}"
    end
    private_class_method :parse_time
  end
end
