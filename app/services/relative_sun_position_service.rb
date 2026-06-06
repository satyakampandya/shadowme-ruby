class RelativeSunPositionService
  # Determines the side of the vehicle the sun is shining on.
  # vehicle_bearing: vehicle heading (0 to 360)
  # sun_azimuth: sun azimuth (0 to 360)
  # Returns: :left, :right, :front, or :behind
  def self.calculate(vehicle_bearing:, sun_azimuth:)
    delta = (sun_azimuth.to_f - vehicle_bearing.to_f) % 360.0

    # Float comparison with a small epsilon to handle precision errors.
    epsilon = 1e-9

    if delta.abs < epsilon || (delta - 360.0).abs < epsilon
      :front
    elsif (delta - 180.0).abs < epsilon
      :behind
    elsif delta > 0.0 && delta < 180.0
      :right
    else
      :left
    end
  end
end
