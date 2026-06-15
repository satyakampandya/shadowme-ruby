module ShadowMe
  module BearingCalculator
    # ponytail: simplified mathematical bearing calculation
    # rubocop:disable Metrics/AbcSize
    def self.calculate(lat1, lng1, lat2, lng2)
      r_lat1 = lat1.to_f * Math::PI / 180.0
      r_lat2 = lat2.to_f * Math::PI / 180.0
      d_lng = (lng2.to_f - lng1.to_f) * Math::PI / 180.0
      y = Math.sin(d_lng) * Math.cos(r_lat2)
      x = (Math.cos(r_lat1) * Math.sin(r_lat2)) - (Math.sin(r_lat1) * Math.cos(r_lat2) * Math.cos(d_lng))
      ((Math.atan2(y, x) * 180.0 / Math::PI) + 360.0) % 360.0
    end
    # rubocop:enable Metrics/AbcSize
  end
end
