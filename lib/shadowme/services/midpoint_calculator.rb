module ShadowMe
  module MidpointCalculator
    # ponytail: simple arithmetic midpoint calculation
    def self.calculate(lat1, lng1, lat2, lng2)
      [(lat1.to_f + lat2.to_f) / 2.0, (lng1.to_f + lng2.to_f) / 2.0]
    end
  end
end
