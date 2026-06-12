module ShadowMe
  class PolylineDecoder
    # Decodes a Google encoded polyline string into an array of [lat, lng] pairs.
    def self.decode(encoded_str)
      points = []
      index = lat = lng = 0
      while index < encoded_str.length
        dlat, index = decode_next_value(encoded_str, index)
        dlng, index = decode_next_value(encoded_str, index)
        points << [(lat += dlat) * 1e-5, (lng += dlng) * 1e-5]
      end
      points
    end

    def self.decode_next_value(encoded_str, index)
      shift = result = 0
      loop do
        b = encoded_str[index].ord - 63
        index += 1
        result |= (b & 0x1f) << shift
        shift += 5
        break unless b >= 0x20
      end
      [(result.nobits?(1) ? (result >> 1) : ~(result >> 1)), index]
    end

    private_class_method :decode_next_value
  end
end
