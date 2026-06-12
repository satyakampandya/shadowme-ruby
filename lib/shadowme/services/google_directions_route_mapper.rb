module ShadowMe
  class GoogleDirectionsRouteMapper
    # Maps Google Directions response data to a flat array of RouteStep models.
    # Raises: InvalidRouteError if the route does not exist.
    def self.map_to_steps(data, route_index)
      routes = data[:routes]
      raise InvalidRouteError, 'Google Directions response did not contain any routes' if routes.nil? || routes.empty?

      if route_index.negative? || route_index >= routes.size
        raise InvalidRouteError, "Requested route index #{route_index} does not exist (total routes: #{routes.size})"
      end

      selected_route = routes[route_index]
      legs = selected_route[:legs] || []

      steps = []
      legs.each do |leg|
        leg_steps = leg[:steps] || []
        leg_steps.each do |step_data|
          steps.concat(RouteStepSegmenter.segment(step_data))
        end
      end

      raise InvalidRouteError, 'No valid steps found in the route legs' if steps.empty?

      steps
    end
  end
end
