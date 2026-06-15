module ShadowMe
  class RouteStepSegmenter
    HEADING_THRESHOLD = 10.0

    # ponytail: simplified polyline segmentation & heading change merging with rounding correction
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.segment(step_data)
      return [] unless step_data.values_at(:start_location, :end_location, :duration, :distance).all?

      total_dur = step_data[:duration][:value]
      total_dist = step_data[:distance][:value]

      pts = step_data[:polyline] && step_data[:polyline][:points]
      points = pts ? PolylineDecoder.decode(pts) : []
      return [single_step(step_data, total_dur, total_dist)] if points.size < 2

      raw = (points.size - 1).times.map do |i|
        lat1, lng1 = points[i]
        lat2, lng2 = points[i + 1]
        d_lat = lat2 - lat1
        dx = (lng2 - lng1) * Math.cos((lat1 + lat2) / 2.0 * Math::PI / 180.0)
        len = Math.sqrt((d_lat * d_lat) + (dx * dx))
        { start_lat: lat1, start_lng: lng1, end_lat: lat2, end_lng: lng2, len: len,
          bearing: BearingCalculator.calculate(lat1, lng1, lat2, lng2) }
      end

      total_len = raw.sum { |s| s[:len] }
      return [single_step(step_data, total_dur, total_dist)] if total_len <= 0.0

      groups = []
      curr = nil

      raw.each do |seg|
        seg_dur = total_dur.to_f * (seg[:len] / total_len)
        seg_dist = total_dist.to_f * (seg[:len] / total_len)

        if curr.nil?
          curr = seg.merge(duration: seg_dur, distance: seg_dist)
        else
          diff = (seg[:bearing] - curr[:bearing]).abs
          if (diff > 180.0 ? 360.0 - diff : diff) <= HEADING_THRESHOLD
            curr[:end_lat] = seg[:end_lat]
            curr[:end_lng] = seg[:end_lng]
            curr[:duration] += seg_dur
            curr[:distance] += seg_dist
          else
            groups << curr
            curr = seg.merge(duration: seg_dur, distance: seg_dist)
          end
        end
      end
      groups << curr if curr

      # rounding correction
      dur_sum = dist_sum = 0
      steps = groups[0...-1].map do |g|
        dur = g[:duration].round
        dist = g[:distance].round
        dur_sum += dur
        dist_sum += dist
        RouteStep.new(
          start_lat: g[:start_lat], start_lng: g[:start_lng],
          end_lat: g[:end_lat], end_lng: g[:end_lng],
          duration: dur, distance: dist
        )
      end

      if (last = groups.last)
        steps << RouteStep.new(
          start_lat: last[:start_lat], start_lng: last[:start_lng],
          end_lat: last[:end_lat], end_lng: last[:end_lng],
          duration: total_dur - dur_sum, distance: total_dist - dist_sum
        )
      end
      steps
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def self.single_step(data, dur, dist)
      RouteStep.new(start_lat: data[:start_location][:lat], start_lng: data[:start_location][:lng],
                    end_lat: data[:end_location][:lat], end_lng: data[:end_location][:lng],
                    duration: dur, distance: dist)
    end
    private_class_method :single_step
  end
end
