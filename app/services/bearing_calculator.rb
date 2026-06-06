class BearingCalculator
  # Calculates the initial bearing (heading) from start to end location in degrees.
  # 0° = North, 90° = East, 180° = South, 270° = West.
  def self.calculate(start_lat, start_lng, end_lat, end_lng)
    lat1 = to_radians(start_lat)
    lng1 = to_radians(start_lng)
    lat2 = to_radians(end_lat)
    lng2 = to_radians(end_lng)

    d_lng = lng2 - lng1

    y = Math.sin(d_lng) * Math.cos(lat2)
    x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(d_lng)

    bearing_radians = Math.atan2(y, x)
    (to_degrees(bearing_radians) + 360.0) % 360.0
  end

  private

  def self.to_radians(degrees)
    degrees.to_f * Math::PI / 180.0
  end

  def self.to_degrees(radians)
    radians * 180.0 / Math::PI
  end
end
