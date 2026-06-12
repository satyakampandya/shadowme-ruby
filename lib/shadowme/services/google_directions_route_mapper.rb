module ShadowMe
  class GoogleDirectionsRouteMapper
    # Maps Google Directions response data to a flat array of RouteStep models.
    # Raises: InvalidRouteError if the route does not exist.
    def self.map_to_steps(data, route_index)
      selected_route = get_route(data, route_index)
      steps = extract_route_steps(selected_route)
      raise InvalidRouteError, 'No valid steps found in the route legs' if steps.empty?

      steps
    end

    def self.get_route(data, route_index)
      routes = data[:routes]
      raise InvalidRouteError, 'Google Directions response did not contain any routes' if routes.nil? || routes.empty?

      if route_index.negative? || route_index >= routes.size
        raise InvalidRouteError, "Requested route index #{route_index} does not exist (total routes: #{routes.size})"
      end

      routes[route_index]
    end

    def self.extract_route_steps(selected_route)
      steps = []
      (selected_route[:legs] || []).each do |leg|
        (leg[:steps] || []).each do |step_data|
          steps.concat(RouteStepSegmenter.segment(step_data))
        end
      end
      steps
    end

    private_class_method :get_route, :extract_route_steps
  end
end
