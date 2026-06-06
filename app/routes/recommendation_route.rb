require 'time'
require 'oj'

class App
  hash_branch('api') do |r|
    r.on 'v1' do
      r.on 'recommendation' do
        r.post do
          # 1. Parse and validate the incoming JSON request
          validator = RecommendationValidator.new
          # Roda's json_parser plugin populates r.params
          validation_result = validator.call(r.params || {})

          unless validation_result.success?
            raise ValidationError.new("Validation failed", validation_result.errors.to_h)
          end

          # Extract validated parameters
          source = validation_result[:source]
          destination = validation_result[:destination]
          departure_time_str = validation_result[:departure_time]
          departure_time = Time.parse(departure_time_str)

          # Store context for structured logging
          @source = source
          @destination = destination

          # 2. Check cache (fail open if Redis is down)
          cached = TripCache.get(
            source: source,
            destination: destination,
            departure_time: departure_time
          )

          if cached
            @cache_hit = true
            response['Content-Type'] = 'application/json'
            r.halt(200, Oj.dump(cached, mode: :compat))
          end

          # 3. Cache miss: Analyze the trip route and calculate recommendation
          trip_request = TripRequest.new(
            source: source,
            destination: destination,
            departure_time: departure_time
          )

          analyzer = TripAnalyzerService.new
          recommendation = analyzer.analyze(trip_request)

          # 4. Serialize the recommendation model
          result_hash = RecommendationSerializer.to_hash(recommendation)

          # 5. Populate Cache
          TripCache.set(
            source: source,
            destination: destination,
            departure_time: departure_time,
            recommendation_hash: result_hash
          )

          response['Content-Type'] = 'application/json'
          Oj.dump(result_hash, mode: :compat)
        end
      end
    end
  end
end
