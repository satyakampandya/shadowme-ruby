module ShadowMe
  class MidpointCalculator
    # Computes the simple arithmetic midpoint of start and end coordinates.
    # As per the technical guideline:
    # mid_lat = (start_lat + end_lat) / 2.0
    # mid_lng = (start_lng + end_lng) / 2.0
    def self.calculate(start_lat, start_lng, end_lat, end_lng)
      mid_lat = (start_lat.to_f + end_lat.to_f) / 2.0
      mid_lng = (start_lng.to_f + end_lng.to_f) / 2.0
      [mid_lat, mid_lng]
    end
  end
end
