require_relative '../test_helper'

class ShadowMeTest < Minitest::Test
  def test_calculate_validation_failure
    assert_raises(ShadowMe::ValidationError) do
      ShadowMe.calculate('', '23.0225,72.5714', 'not-a-timestamp')
    end
  end

  def test_calculate_success
    departure_time = Time.parse('2026-06-10T08:00:00+05:30')

    mock_response = {
      status: 'OK',
      routes: [
        {
          legs: [
            {
              steps: [
                {
                  distance: { value: 10_000 },
                  duration: { value: 1800 },
                  start_location: { lat: 21.17, lng: 72.83 },
                  end_location: { lat: 23.02, lng: 72.57 }
                }
              ]
            }
          ]
        }
      ]
    }

    stub_request(:get, 'https://maps.googleapis.com/maps/api/directions/json')
      .with(query: { origin: '21.1702,72.8311', destination: '23.0225,72.5714', alternatives: 'true',
                     key: 'test-api-key', departure_time: departure_time.to_i.to_s })
      .to_return(status: 200, body: Oj.dump(mock_response,
                                            mode: :compat), headers: { 'Content-Type' => 'application/json' })

    result = ShadowMe.calculate(
      '21.1702,72.8311',
      '23.0225,72.5714',
      departure_time,
      include_steps: true
    )

    assert_kind_of Hash, result
    assert_includes %w[left right], result[:recommended_side]
    assert_operator result[:left_exposure_minutes], :>=, 0
    assert_operator result[:right_exposure_minutes], :>=, 0
    assert_includes %w[low medium high], result[:confidence]
    assert_kind_of Array, result[:steps]
    refute_empty result[:steps]
  end
end
