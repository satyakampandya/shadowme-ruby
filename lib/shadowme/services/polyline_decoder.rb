module ShadowMe
  class PolylineDecoder
    # Decodes a Google encoded polyline string into an array of [lat, lng] pairs.
    def self.decode(encoded_str)
      points = []
      index = 0
      len = encoded_str.length
      lat = 0
      lng = 0

      while index < len
        # Decode Latitude
        shift = 0
        result = 0
        loop do
          b = encoded_str[index].ord - 63
          index += 1
          result |= (b & 0x1f) << shift
          shift += 5
          break unless b >= 0x20
        end
        dlat = (result.nobits?(1) ? (result >> 1) : ~(result >> 1))
        lat += dlat

        # Decode Longitude
        shift = 0
        result = 0
        loop do
          b = encoded_str[index].ord - 63
          index += 1
          result |= (b & 0x1f) << shift
          shift += 5
          break unless b >= 0x20
        end
        dlng = (result.nobits?(1) ? (result >> 1) : ~(result >> 1))
        lng += dlng

        points << [lat * 1e-5, lng * 1e-5]
      end
      points
    end
  end
end
