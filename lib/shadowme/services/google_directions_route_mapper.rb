module ShadowMe
  module GoogleDirectionsRouteMapper
    # ponytail: simplified mapping logic
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.map_to_steps(data, route_index)
      routes = data[:routes]
      raise InvalidRouteError, 'Google Directions response did not contain any routes' if routes.nil? || routes.empty?

      if route_index.negative? || route_index >= routes.size
        raise InvalidRouteError, "Requested route index #{route_index} does not exist (total routes: #{routes.size})"
      end

      steps = []
      (routes[route_index][:legs] || []).each do |leg|
        (leg[:steps] || []).each do |step_data|
          steps.concat(RouteStepSegmenter.segment(step_data))
        end
      end
      raise InvalidRouteError, 'No valid steps found in the route legs' if steps.empty?

      steps
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
