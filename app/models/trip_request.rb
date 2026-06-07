class TripRequest
  attr_reader :source, :destination, :departure_time, :route_index

  def initialize(source:, destination:, departure_time:, route_index: 0)
    @source = source
    @destination = destination
    @departure_time = departure_time
    @route_index = route_index || 0
  end
end
