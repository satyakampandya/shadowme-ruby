class TripRequest
  attr_reader :source, :destination, :departure_time

  def initialize(source:, destination:, departure_time:)
    @source = source
    @destination = destination
    @departure_time = departure_time
  end
end
