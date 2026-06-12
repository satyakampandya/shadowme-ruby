require_relative '../test_helper'

module ShadowMe
  class RouteStepSegmenterTest < Minitest::Test
    def test_segment_returns_empty_on_invalid_step_data
      step_data = { start_location: { lat: 1.0 } } # missing fields
      assert_equal [], RouteStepSegmenter.segment(step_data)
    end

    def test_segment_no_polyline_returns_single_step
      step_data = {
        start_location: { lat: 10.0, lng: 20.0 },
        end_location: { lat: 10.1, lng: 20.1 },
        duration: { value: 100 },
        distance: { value: 1000 }
      }
      steps = RouteStepSegmenter.segment(step_data)
      assert_equal 1, steps.size
      assert_equal 10.0, steps.first.start_lat
      assert_equal 10.1, steps.first.end_lat
      assert_equal 100, steps.first.duration
      assert_equal 1000, steps.first.distance
    end

    def test_rounding_delta_correction_preserves_totals
      step_data = {
        start_location: { lat: 10.0, lng: 20.0 },
        end_location: { lat: 10.3, lng: 20.3 },
        duration: { value: 10 },
        distance: { value: 100 },
        polyline: { points: 'mock_polyline' }
      }

      # Mock polyline decode to return 4 points (3 raw segments)
      # Segments will have equal length. So duration/distance will be split as:
      # Segment 1: duration = 10 / 3 = 3.333 -> round = 3
      # Segment 2: duration = 10 / 3 = 3.333 -> round = 3
      # Segment 3: duration = 10 / 3 = 3.333 -> final segment correction
      # Rounded sum without correction: 3 + 3 + 3 = 9 (loses 1)
      # With correction: Segment 3 duration = 10 - (3 + 3) = 4. Total = 10.
      class << PolylineDecoder
        alias_method :original_decode, :decode
        remove_method :decode
      end
      PolylineDecoder.define_singleton_method(:decode) do |_str|
        [[10.0, 20.0], [10.1, 20.1], [10.0, 20.2], [10.1, 20.3]]
      end

      begin
        steps = RouteStepSegmenter.segment(step_data)
        assert_equal 3, steps.size

        # Verify the sum of durations is exactly 10
        total_duration = steps.map(&:duration).sum
        assert_equal 10, total_duration

        # Verify segments details
        assert_equal 3, steps[0].duration
        assert_equal 3, steps[1].duration
        assert_equal 4, steps[2].duration # receives the rounding delta

        # Verify the sum of distances is exactly 100
        total_distance = steps.map(&:distance).sum
        assert_equal 100, total_distance
      ensure
        class << PolylineDecoder
          remove_method :decode
          alias_method :decode, :original_decode
          remove_method :original_decode
        end
      end
    end
  end
end
