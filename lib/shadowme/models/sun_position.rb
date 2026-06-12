module ShadowMe
  class SunPosition
    attr_reader :azimuth, :elevation

    def initialize(azimuth:, elevation:)
      @azimuth = azimuth.to_f
      @elevation = elevation.to_f
    end
  end
end
