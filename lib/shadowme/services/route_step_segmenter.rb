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

      def valid_step_data?(step_data)
        !!(step_data[:start_location] && step_data[:end_location] && step_data[:duration] && step_data[:distance])
      end

      def decode_points(step_data)
        encoded_points = step_data[:polyline] && step_data[:polyline][:points]
        encoded_points ? PolylineDecoder.decode(encoded_points) : []
      end

      def single_step(step_data, duration, distance)
        [
          RouteStep.new(
            start_lat: step_data[:start_location][:lat],
            start_lng: step_data[:start_location][:lng],
            end_lat: step_data[:end_location][:lat],
            end_lng: step_data[:end_location][:lng],
            duration: duration,
            distance: distance
          )
        ]
      end

      def build_raw_segments(points)
        raw_segments = []
        total_len = 0.0

        (points.size - 1).times do |i|
          lat1, lng1 = points[i]
          lat2, lng2 = points[i + 1]

          d_lat = lat2 - lat1
          d_lng = lng2 - lng1
          mid_lat_rad = (lat1 + lat2) / 2.0 * Math::PI / 180.0
          dx = d_lng * Math.cos(mid_lat_rad)
          len = Math.sqrt((d_lat * d_lat) + (dx * dx))

          bearing = BearingCalculator.calculate(lat1, lng1, lat2, lng2)

          raw_segments << {
            start_lat: lat1,
            start_lng: lng1,
            end_lat: lat2,
            end_lng: lng2,
            len: len,
            bearing: bearing
          }
          total_len += len
        end

        [raw_segments, total_len]
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
          if current_group.nil?
            current_group = {
              start_lat: seg[:start_lat],
              start_lng: seg[:start_lng],
              end_lat: seg[:end_lat],
              end_lng: seg[:end_lng],
              duration: seg[:duration],
              distance: seg[:distance],
              bearing: seg[:bearing]
            }
          else
            diff = (seg[:bearing] - current_group[:bearing]).abs
            diff = 360.0 - diff if diff > 180.0

            if diff <= HEADING_THRESHOLD
              current_group[:end_lat] = seg[:end_lat]
              current_group[:end_lng] = seg[:end_lng]
              current_group[:duration] += seg[:duration]
              current_group[:distance] += seg[:distance]
            else
              groups << current_group
              current_group = {
                start_lat: seg[:start_lat],
                start_lng: seg[:start_lng],
                end_lat: seg[:end_lat],
                end_lng: seg[:end_lng],
                duration: seg[:duration],
                distance: seg[:distance],
                bearing: seg[:bearing]
              }
            end
          end
        end

        groups << current_group if current_group
        groups
      end

      def build_steps_with_rounding_correction(groups, total_duration, total_distance)
        steps = []
        accumulated_duration = 0
        accumulated_distance = 0

        groups.each_with_index do |group, index|
          if index == groups.size - 1
            final_duration = total_duration - accumulated_duration
            final_distance = total_distance - accumulated_distance

            steps << RouteStep.new(
              start_lat: group[:start_lat],
              start_lng: group[:start_lng],
              end_lat: group[:end_lat],
              end_lng: group[:end_lng],
              duration: final_duration,
              distance: final_distance
            )
          else
            rounded_duration = group[:duration].round
            rounded_distance = group[:distance].round

            accumulated_duration += rounded_duration
            accumulated_distance += rounded_distance

            steps << RouteStep.new(
              start_lat: group[:start_lat],
              start_lng: group[:start_lng],
              end_lat: group[:end_lat],
              end_lng: group[:end_lng],
              duration: rounded_duration,
              distance: rounded_distance
            )
          end
        end

        steps
      end
    end
  end
end
