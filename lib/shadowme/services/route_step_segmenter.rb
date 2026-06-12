# rubocop:disable Metrics/ClassLength
module ShadowMe
  class RouteStepSegmenter
    HEADING_THRESHOLD = 10.0

    class << self
      # Segments a single Google Directions step into one or more RouteStep models.
      # Decodes polylines to detect curves, merges straight segments, and applies
      # rounding error correction to preserve total duration and distance.
      def segment(step_data)
        return [] unless valid_step_data?(step_data)

        total_duration = step_data[:duration][:value]
        total_distance = step_data[:distance][:value]

        points = decode_points(step_data)
        return single_step(step_data, total_duration, total_distance) if points.size < 2

        raw_segs, total_len = build_raw_segments(points)
        return single_step(step_data, total_duration, total_distance) if total_len <= 0.0

        allocate_durations_and_distances!(raw_segs, total_len, total_duration, total_distance)
        groups = merge_segments(raw_segs)
        build_steps_with_rounding_correction(groups, total_duration, total_distance)
      end

      private

      def valid_step_data?(data)
        !!(data[:start_location] && data[:end_location] && data[:duration] && data[:distance])
      end

      def decode_points(data)
        pts = data[:polyline] && data[:polyline][:points]
        pts ? PolylineDecoder.decode(pts) : []
      end

      def single_step(data, dur, dist)
        [RouteStep.new(
          start_lat: data[:start_location][:lat], start_lng: data[:start_location][:lng],
          end_lat: data[:end_location][:lat], end_lng: data[:end_location][:lng],
          duration: dur, distance: dist
        )]
      end

      def build_raw_segments(points)
        raw_segments = (points.size - 1).times.map do |idx|
          lat1, lng1 = points[idx]
          lat2, lng2 = points[idx + 1]
          { start_lat: lat1, start_lng: lng1, end_lat: lat2, end_lng: lng2,
            len: calculate_distance(lat1, lng1, lat2, lng2),
            bearing: BearingCalculator.calculate(lat1, lng1, lat2, lng2) }
        end
        [raw_segments, raw_segments.sum { |s| s[:len] }]
      end

      def calculate_distance(lat1, lng1, lat2, lng2)
        d_lat = lat2 - lat1
        dx = (lng2 - lng1) * Math.cos((lat1 + lat2) / 2.0 * Math::PI / 180.0)
        Math.sqrt((d_lat * d_lat) + (dx * dx))
      end

      def allocate_durations_and_distances!(raw_segments, total_len, total_duration, total_distance)
        raw_segments.each do |seg|
          seg[:duration] = total_duration.to_f * (seg[:len] / total_len)
          seg[:distance] = total_distance.to_f * (seg[:len] / total_len)
        end
      end

      def merge_segments(raw_segments)
        groups = []
        current_group = nil
        raw_segments.each do |seg|
          current_group = process_segment(groups, current_group, seg)
        end
        groups << current_group if current_group
        groups
      end

      def process_segment(groups, current, seg)
        if current.nil?
          init_group(seg)
        elsif bearing_diff(seg[:bearing], current[:bearing]) <= HEADING_THRESHOLD
          merge_to_group!(current, seg)
          current
        else
          groups << current
          init_group(seg)
        end
      end

      def init_group(seg)
        { start_lat: seg[:start_lat], start_lng: seg[:start_lng], end_lat: seg[:end_lat], end_lng: seg[:end_lng],
          duration: seg[:duration], distance: seg[:distance], bearing: seg[:bearing] }
      end

      def bearing_diff(bearing1, bearing2)
        diff = (bearing1 - bearing2).abs
        diff > 180.0 ? 360.0 - diff : diff
      end

      def merge_to_group!(current, seg)
        current[:end_lat] = seg[:end_lat]
        current[:end_lng] = seg[:end_lng]
        current[:duration] += seg[:duration]
        current[:distance] += seg[:distance]
      end

      def build_steps_with_rounding_correction(groups, total_dur, total_dist)
        state = { dur: 0, dist: 0, steps: [] }
        groups[0...-1].each { |g| process_rounding_step(state, g) }
        return state[:steps] if groups.empty?

        last_dur = total_dur - state[:dur]
        last_dist = total_dist - state[:dist]
        state[:steps] << build_step_model(groups[-1], last_dur, last_dist)
      end

      def process_rounding_step(state, group)
        dur = group[:duration].round
        dist = group[:distance].round
        state[:dur] += dur
        state[:dist] += dist
        state[:steps] << build_step_model(group, dur, dist)
      end

      def build_step_model(group, dur, dist)
        RouteStep.new(start_lat: group[:start_lat], start_lng: group[:start_lng],
                      end_lat: group[:end_lat], end_lng: group[:end_lng],
                      duration: dur, distance: dist)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
