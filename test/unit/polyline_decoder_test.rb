require_relative '../test_helper'

class PolylineDecoderTest < Minitest::Test
  def test_decodes_simple_polyline
    # Encoded polyline for points: [[38.5, -120.2], [40.7, -120.95], [43.252, -126.453]]
    # Google standard encoding example string: "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
    points = PolylineDecoder.decode("_p~iF~ps|U_ulLnnqC_mqNvxq`@")

    assert_equal 3, points.size
    assert_in_delta 38.5, points[0][0]
    assert_in_delta(-120.2, points[0][1])
    assert_in_delta 40.7, points[1][0]
    assert_in_delta(-120.95, points[1][1])
    assert_in_delta 43.252, points[2][0]
    assert_in_delta(-126.453, points[2][1])
  end

  def test_decodes_empty_string_to_empty_array
    assert_equal [], PolylineDecoder.decode("")
  end
end
