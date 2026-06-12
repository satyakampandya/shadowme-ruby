module ShadowMe
  class BearingCalculator
    # Calculates the initial bearing (heading) from start to end location in degrees.
    # 0° = North, 90° = East, 180° = South, 270° = West.
    def self.calculate(start_lat, start_lng, end_lat, end_lng)
      y, x = calculate_xy(to_radians(start_lat), to_radians(start_lng),
                          to_radians(end_lat), to_radians(end_lng))
      (to_degrees(Math.atan2(y, x)) + 360.0) % 360.0
    end

    def self.calculate_xy(lat1, lng1, lat2, lng2)
      d_lng = lng2 - lng1
      y = Math.sin(d_lng) * Math.cos(lat2)
      x = (Math.cos(lat1) * Math.sin(lat2)) - (Math.sin(lat1) * Math.cos(lat2) * Math.cos(d_lng))
      [y, x]
    end

    def self.to_radians(degrees)
      degrees.to_f * Math::PI / 180.0
    end

    def self.to_degrees(radians)
      radians * 180.0 / Math::PI
    end

    private_class_method :calculate_xy, :to_radians, :to_degrees
  end
end
