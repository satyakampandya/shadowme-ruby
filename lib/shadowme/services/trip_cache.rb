require 'digest'
require 'redis'
require 'oj'

module ShadowMe
  class TripCache
    # Cache TTL is set to 24 hours (86400 seconds)
    TTL = 86_400

    # Fetches cached recommendation if available, otherwise returns nil.
    def self.get(source:, destination:, departure_time:, route_index: 0, include_steps: false)
      client = redis_client
      return nil unless client

      key = generate_key(source: source, destination: destination, departure_time: departure_time, route_index: route_index, include_steps: include_steps)
      cached_data = client.get(key)
      
      if cached_data
        Oj.load(cached_data, symbol_keys: true)
      end
    rescue => e
      # Log error to stderr and fail open (bypass cache)
      warn "[TripCache] Redis read error: #{e.message}"
      nil
    end

    # Caches a recommendation hash.
    def self.set(source:, destination:, departure_time:, route_index: 0, include_steps: false, recommendation_hash:)
      client = redis_client
      return unless client

      key = generate_key(source: source, destination: destination, departure_time: departure_time, route_index: route_index, include_steps: include_steps)
      serialized = Oj.dump(recommendation_hash, mode: :compat)
      
      client.setex(key, TTL, serialized)
    rescue => e
      # Log error to stderr and fail open
      warn "[TripCache] Redis write error: #{e.message}"
    end

    # Helper to generate a unique cache key based on route inputs
    def self.generate_key(source:, destination:, departure_time:, route_index: 0, include_steps: false)
      normalized_source = source.to_s.strip.downcase
      normalized_destination = destination.to_s.strip.downcase
      # Standardize departure_time to string
      normalized_time = departure_time.to_s

      raw_string = "#{normalized_source}|#{normalized_destination}|#{normalized_time}|#{route_index || 0}|#{include_steps ? '1' : '0'}"
      hash = Digest::SHA256.hexdigest(raw_string)
      "shadowme:recommendation:#{hash}"
    end

    # Lazily establishes connection and pings Redis to ensure readiness.
    def self.redis_client
      return @redis_client if defined?(@redis_client)

      url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379/0'
      client = Redis.new(url: url)
      
      # Verify connectivity
      client.ping
      @redis_client = client
    rescue => e
      warn "[TripCache] Redis is not available: #{e.message}"
      @redis_client = nil
    end

    # Reset cached client connection (useful for testing)
    def self.reset_client!
      remove_instance_variable(:@redis_client) if defined?(@redis_client)
    end
  end
end
