require 'time'
require 'oj'

class App
  hash_branch('api') do |r|
    r.on 'v1' do
      r.on 'recommendation' do
        r.post do
          # 1. Parse and validate the incoming JSON request
          validator = ShadowMe::RecommendationValidator.new
          # Roda's json_parser plugin populates r.params
          validation_result = validator.call(r.params || {})

          unless validation_result.success?
            raise ShadowMe::ValidationError.new('Validation failed', validation_result.errors.to_h)
          end

          # Extract validated parameters
          source = validation_result[:source]
          destination = validation_result[:destination]
          departure_time_str = validation_result[:departure_time]
          departure_time = Time.parse(departure_time_str)
          route_index = validation_result[:route_index] || 0
          include_steps = validation_result[:include_steps] == true

          # Store context for structured logging
          r.env['shadowme.source'] = source
          r.env['shadowme.destination'] = destination

          # 2. Analyze the trip route and calculate recommendation
          result_hash = ShadowMe.calculate(
            source,
            destination,
            departure_time,
            route_index: route_index,
            include_steps: include_steps
          )

          response.status = 200
          response['Content-Type'] = 'application/json'
          Oj.dump(result_hash, mode: :compat)
        end
      end
    end
  end
end
