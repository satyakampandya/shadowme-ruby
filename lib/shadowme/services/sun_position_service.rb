require 'time'
require 'sun_calc'

module ShadowMe
  class SunPositionService
    # Calculates the sun's position (azimuth and elevation in degrees) at a given location and time.
    # Returns a SunPosition model.
    def self.calculate(latitude:, longitude:, datetime:)
      time = parse_time(datetime)

      # sun_position returns: { azimuth: <radians>, altitude: <radians> }
      # altitude is the elevation angle.
      pos = SunCalc.sun_position(time, latitude.to_f, longitude.to_f)

      # Convert SunCalc azimuth (radians from South to West) to standard
      # navigation azimuth (degrees clockwise from North)
      azimuth_deg = pos[:azimuth] * 180.0 / Math::PI
      standard_azimuth = (azimuth_deg + 180.0) % 360.0

      # Convert altitude to elevation in degrees
      elevation_deg = pos[:altitude] * 180.0 / Math::PI

      SunPosition.new(azimuth: standard_azimuth, elevation: elevation_deg)
    rescue StandardError => e
      raise SunCalculationError, "Failed to calculate sun position: #{e.message}"
    end

    def self.parse_time(datetime)
      case datetime
      when String then Time.parse(datetime)
      when Time then datetime
      when DateTime then datetime.to_time
      else raise ArgumentError, "Unsupported datetime type: #{datetime.class}"
      end
    rescue StandardError => e
      raise SunCalculationError, "Invalid departure_time/datetime format: #{e.message}"
    end
    private_class_method :parse_time
  end
end
