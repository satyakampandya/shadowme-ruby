module ShadowMe
  module RelativeSunPositionService
    TOLERANCE = 5.0

    # ponytail: simplified sun side relative to bearing check
    def self.calculate(vehicle_bearing:, sun_azimuth:)
      delta = (sun_azimuth.to_f - vehicle_bearing.to_f) % 360.0
      return :front if delta <= TOLERANCE || delta >= (360.0 - TOLERANCE)

      return :behind if (delta - 180.0).abs <= TOLERANCE

      delta > TOLERANCE && delta < (180.0 - TOLERANCE) ? :right : :left
    end
  end
end
