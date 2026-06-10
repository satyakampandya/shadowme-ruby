require_relative '../test_helper'

class SeatRecommendationServiceTest < Minitest::Test
  def test_recommends_left_side_when_left_has_less_exposure
    # Left: 15 min, Right: 72 min. Diff = 57 / 87 = 65.5% => high confidence
    rec = SeatRecommendationService.recommend(left_exposure_seconds: 900, right_exposure_seconds: 4320)

    assert_equal 'left', rec.recommended_side
    assert_equal 15, rec.left_exposure_minutes
    assert_equal 72, rec.right_exposure_minutes
    assert_equal 'high', rec.confidence
    assert_equal 'You should sit on the left side of the vehicle to minimize direct sunlight exposure.', rec.message
  end

  def test_recommends_right_side_when_right_has_less_exposure
    # Left: 60 min, Right: 40 min. Diff = 20 / 100 = 20% => medium confidence
    rec = SeatRecommendationService.recommend(left_exposure_seconds: 3600, right_exposure_seconds: 2400)

    assert_equal 'right', rec.recommended_side
    assert_equal 60, rec.left_exposure_minutes
    assert_equal 40, rec.right_exposure_minutes
    assert_equal 'medium', rec.confidence
    assert_equal 'You should sit on the right side of the vehicle to minimize direct sunlight exposure.', rec.message
  end

  def test_recommends_side_with_low_confidence_if_similar
    # Left: 51 min, Right: 49 min. Diff = 2 / 100 = 2% => low confidence
    rec = SeatRecommendationService.recommend(left_exposure_seconds: 3060, right_exposure_seconds: 2940)

    assert_equal 'right', rec.recommended_side
    assert_equal 'low', rec.confidence
    assert_equal 'You should sit on the right side of the vehicle to minimize direct sunlight exposure.', rec.message
  end

  def test_handles_no_exposure_gracefully
    rec = SeatRecommendationService.recommend(left_exposure_seconds: 0, right_exposure_seconds: 0)

    assert_equal 'right', rec.recommended_side
    assert_equal 0, rec.left_exposure_minutes
    assert_equal 0, rec.right_exposure_minutes
    assert_equal 'low', rec.confidence
    assert_equal 'You should sit on the right side of the vehicle to minimize direct sunlight exposure.', rec.message
  end

  def test_recommends_either_when_entirely_night
    rec = SeatRecommendationService.recommend(
      left_exposure_seconds: 0,
      right_exposure_seconds: 0,
      night_exposure_seconds: 3600,
      is_entirely_night: true
    )

    assert_equal 'either', rec.recommended_side
    assert_equal 0, rec.left_exposure_minutes
    assert_equal 0, rec.right_exposure_minutes
    assert_equal 60, rec.night_exposure_minutes
    assert_equal 'high', rec.confidence
    assert_equal 'It is night time, enjoy your journey!', rec.message
  end

  def test_handles_partial_night_time
    rec = SeatRecommendationService.recommend(
      left_exposure_seconds: 900,
      right_exposure_seconds: 2700,
      night_exposure_seconds: 1800,
      is_entirely_night: false
    )

    assert_equal 'left', rec.recommended_side
    assert_equal 15, rec.left_exposure_minutes
    assert_equal 45, rec.right_exposure_minutes
    assert_equal 30, rec.night_exposure_minutes
    assert_equal 'high', rec.confidence
    assert_equal 'You should sit on the left side of the vehicle to minimize direct sunlight exposure.', rec.message
  end

  def test_handles_front_behind_exposure
    rec = SeatRecommendationService.recommend(
      left_exposure_seconds: 900,
      right_exposure_seconds: 2700,
      night_exposure_seconds: 1800,
      front_behind_exposure_seconds: 1200,
      is_entirely_night: false
    )

    assert_equal 'left', rec.recommended_side
    assert_equal 15, rec.left_exposure_minutes
    assert_equal 45, rec.right_exposure_minutes
    assert_equal 30, rec.night_exposure_minutes
    assert_equal 20, rec.front_behind_exposure_minutes
    assert_equal 'high', rec.confidence
    assert_equal 'You should sit on the left side of the vehicle to minimize direct sunlight exposure.', rec.message
  end
end
