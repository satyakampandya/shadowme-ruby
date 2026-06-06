require_relative '../test_helper'

class RouteAnalyzerServiceTest < Minitest::Test
  def test_does_not_subdivide_short_steps
    step = RouteStep.new(
      start_lat: 21.17,
      start_lng: 72.83,
      end_lat: 21.18,
      end_lng: 72.84,
      duration: 300, # 5 minutes
      distance: 2000
    )
    departure_time = Time.parse("2026-06-10T08:00:00+05:30")

    analyzed_steps = []

    # Pure Ruby stubbing to intercept StepAnalyzerService.analyze without warnings
    class << StepAnalyzerService
      alias_method :original_analyze, :analyze
      remove_method :analyze
    end

    StepAnalyzerService.define_singleton_method(:analyze) do |route_step:, trip_start_time:, accumulated_duration_seconds:|
      analyzed_steps << route_step
      original_analyze(route_step: route_step, trip_start_time: trip_start_time, accumulated_duration_seconds: accumulated_duration_seconds)
    end

    begin
      RouteAnalyzerService.analyze(steps: [step], departure_time: departure_time)
    ensure
      # Restore original method without warning
      class << StepAnalyzerService
        remove_method :analyze
        alias_method :analyze, :original_analyze
        remove_method :original_analyze
      end
    end

    assert_equal 1, analyzed_steps.size
    assert_equal step.start_lat, analyzed_steps.first.start_lat
    assert_equal step.end_lat, analyzed_steps.first.end_lat
    assert_equal step.duration, analyzed_steps.first.duration
  end

  def test_subdivides_long_steps_into_equal_segments
    # 25 minutes (1500 seconds) should be divided into 3 sub-steps of 500 seconds
    step = RouteStep.new(
      start_lat: 21.17,
      start_lng: 72.83,
      end_lat: 21.20,
      end_lng: 72.86,
      duration: 1500,
      distance: 15000
    )
    departure_time = Time.parse("2026-06-10T08:00:00+05:30")

    analyzed_steps = []

    class << StepAnalyzerService
      alias_method :original_analyze, :analyze
      remove_method :analyze
    end

    StepAnalyzerService.define_singleton_method(:analyze) do |route_step:, trip_start_time:, accumulated_duration_seconds:|
      analyzed_steps << route_step
      original_analyze(route_step: route_step, trip_start_time: trip_start_time, accumulated_duration_seconds: accumulated_duration_seconds)
    end

    begin
      RouteAnalyzerService.analyze(steps: [step], departure_time: departure_time)
    ensure
      class << StepAnalyzerService
        remove_method :analyze
        alias_method :analyze, :original_analyze
        remove_method :original_analyze
      end
    end

    assert_equal 3, analyzed_steps.size

    # Segment 1 (fraction 0.0 to 0.33)
    assert_in_delta 21.17, analyzed_steps[0].start_lat
    assert_in_delta 72.83, analyzed_steps[0].start_lng
    assert_in_delta 21.18, analyzed_steps[0].end_lat
    assert_in_delta 72.84, analyzed_steps[0].end_lng
    assert_equal 500, analyzed_steps[0].duration
    assert_equal 5000, analyzed_steps[0].distance

    # Segment 2 (fraction 0.33 to 0.66)
    assert_in_delta 21.18, analyzed_steps[1].start_lat
    assert_in_delta 72.84, analyzed_steps[1].start_lng
    assert_in_delta 21.19, analyzed_steps[1].end_lat
    assert_in_delta 72.85, analyzed_steps[1].end_lng
    assert_equal 500, analyzed_steps[1].duration
    assert_equal 5000, analyzed_steps[1].distance

    # Segment 3 (fraction 0.66 to 1.0)
    assert_in_delta 21.19, analyzed_steps[2].start_lat
    assert_in_delta 72.85, analyzed_steps[2].start_lng
    assert_in_delta 21.20, analyzed_steps[2].end_lat
    assert_in_delta 72.86, analyzed_steps[2].end_lng
    assert_equal 500, analyzed_steps[2].duration
    assert_equal 5000, analyzed_steps[2].distance
  end
end
