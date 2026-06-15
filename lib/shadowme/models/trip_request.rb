module ShadowMe
  class TripRequest
    attr_reader :source, :destination, :departure_time, :route_index, :include_steps

    def initialize(source:, destination:, departure_time:, route_index: 0, include_steps: false)
      @source = source
      @destination = destination
      @departure_time = departure_time
      @route_index = route_index || 0
      @include_steps = !!include_steps
    end
  end
end
