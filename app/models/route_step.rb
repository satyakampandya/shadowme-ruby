class RouteStep
  attr_reader :start_lat, :start_lng, :end_lat, :end_lng, :duration, :distance

  def initialize(start_lat:, start_lng:, end_lat:, end_lng:, duration:, distance:)
    @start_lat = start_lat.to_f
    @start_lng = start_lng.to_f
    @end_lat = end_lat.to_f
    @end_lng = end_lng.to_f
    @duration = duration.to_i
    @distance = distance.to_i
  end
end
