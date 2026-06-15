module ShadowMe
  module PolylineDecoder
    # ponytail: simplified loop for google polyline decoding
    def self.decode(encoded)
      points = []
      index = lat = lng = 0
      while index < encoded.length
        lat += decode_val(encoded, index) { |idx| index = idx }
        lng += decode_val(encoded, index) { |idx| index = idx }
        points << [lat * 1e-5, lng * 1e-5]
      end
      points
    end

    def self.decode_val(str, index)
      shift = result = 0
      loop do
        b = str[index].ord - 63
        index += 1
        result |= (b & 0x1f) << shift
        shift += 5
        break unless b >= 0x20
      end
      yield index
      result.nobits?(1) ? (result >> 1) : ~(result >> 1)
    end
    private_class_method :decode_val
  end
end
