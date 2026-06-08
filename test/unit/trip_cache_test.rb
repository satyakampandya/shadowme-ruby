require_relative '../test_helper'

class TripCacheTest < Minitest::Test
  def setup
    @mock_redis = Object.new
    mock_client = @mock_redis
    # Stub redis_client to return our mock using local variable for closure capture without redefinition warnings
    TripCache.singleton_class.send(:remove_method, :redis_client) if TripCache.respond_to?(:redis_client)
    TripCache.define_singleton_method(:redis_client) { mock_client }
  end

  def teardown
    # Reset TripCache to default mock behavior (nil client) without redefinition warnings
    TripCache.singleton_class.send(:remove_method, :redis_client) if TripCache.respond_to?(:redis_client)
    TripCache.define_singleton_method(:redis_client) { nil }
  end

  def test_generate_key_is_consistent_with_whitespace_and_casing
    key1 = TripCache.generate_key(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30"
    )

    key2 = TripCache.generate_key(
      source: "  21.1702,72.8311  ",
      destination: "23.0225,72.5714  ",
      departure_time: "2026-06-10T08:00:00+05:30"
    )

    assert_equal key1, key2
  end

  def test_generate_key_differs_by_include_steps
    key_without_steps = TripCache.generate_key(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30",
      include_steps: false
    )

    key_with_steps = TripCache.generate_key(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10T08:00:00+05:30",
      include_steps: true
    )

    refute_equal key_without_steps, key_with_steps
  end

  def test_get_and_set_operations_serialize_and_deserialize_correctly
    store = {}
    
    # Setup mock store operations
    @mock_redis.define_singleton_method(:get) { |k| store[k] }
    @mock_redis.define_singleton_method(:setex) { |k, ttl, v| store[k] = v }

    rec_hash1 = {
      recommended_side: "left",
      left_exposure_minutes: 15,
      right_exposure_minutes: 72,
      confidence: "high",
      route_index: 0
    }

    rec_hash2 = {
      recommended_side: "right",
      left_exposure_minutes: 40,
      right_exposure_minutes: 10,
      confidence: "high",
      route_index: 1
    }

    TripCache.set(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10",
      route_index: 0,
      recommendation_hash: rec_hash1
    )

    TripCache.set(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10",
      route_index: 1,
      recommendation_hash: rec_hash2
    )

    # Verify both keys were written
    assert_equal 2, store.size

    cached1 = TripCache.get(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10",
      route_index: 0
    )

    cached2 = TripCache.get(
      source: "21.1702,72.8311",
      destination: "23.0225,72.5714",
      departure_time: "2026-06-10",
      route_index: 1
    )

    assert_equal "left", cached1[:recommended_side]
    assert_equal 0, cached1[:route_index]

    assert_equal "right", cached2[:recommended_side]
    assert_equal 1, cached2[:route_index]
  end

  def test_get_fails_open_returning_nil_on_redis_connection_error
    @mock_redis.define_singleton_method(:get) { |_k| raise Redis::BaseError, "Connection refused" }

    # Should rescue and return nil
    assert_nil TripCache.get(source: "21.1702,72.8311", destination: "23.0225,72.5714", departure_time: "2026-06-10")
  end

  def test_set_fails_open_silently_on_redis_connection_error
    @mock_redis.define_singleton_method(:setex) { |_k, _ttl, _v| raise Redis::BaseError, "Connection timeout" }

    # Should rescue and return without raising
    TripCache.set(source: "21.1702,72.8311", destination: "23.0225,72.5714", departure_time: "2026-06-10", recommendation_hash: {})
  end
end
