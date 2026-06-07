class RelativeSunPositionService
  TOLERANCE = 5.0 # Degrees

  # Determines the side of the vehicle the sun is shining on.
  # vehicle_bearing: vehicle heading (0 to 360)
  # sun_azimuth: sun azimuth (0 to 360)
  # Returns: :left, :right, :front, or :behind
  def self.calculate(vehicle_bearing:, sun_azimuth:)
    delta = (sun_azimuth.to_f - vehicle_bearing.to_f) % 360.0

    if delta <= TOLERANCE || delta >= (360.0 - TOLERANCE)
      :front
    elsif (delta - 180.0).abs <= TOLERANCE
      :behind
    elsif delta > TOLERANCE && delta < (180.0 - TOLERANCE)
      :right
    else
      :left
    end
  end
end

