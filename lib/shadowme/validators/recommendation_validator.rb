require 'dry-validation'
require 'time'

module ShadowMe
  class RecommendationValidator < Dry::Validation::Contract
    params do
      required(:source).filled(:string)
      required(:destination).filled(:string)
      required(:departure_time).filled(:string)
      optional(:route_index).filled(:integer, gteq?: 0)
      optional(:include_steps).maybe(:bool)
    end

    rule(:source) do
      unless value.match?(/^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$/)
        key.failure('must be in "latitude,longitude" format')
        next
      end

      lat, lng = value.split(',').map(&:to_f)
      key.failure('latitude must be between -90 and 90') if lat < -90.0 || lat > 90.0
      key.failure('longitude must be between -180 and 180') if lng < -180.0 || lng > 180.0
    end

    rule(:destination) do
      unless value.match?(/^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$/)
        key.failure('must be in "latitude,longitude" format')
        next
      end

      lat, lng = value.split(',').map(&:to_f)
      key.failure('latitude must be between -90 and 90') if lat < -90.0 || lat > 90.0
      key.failure('longitude must be between -180 and 180') if lng < -180.0 || lng > 180.0
    end

    rule(:departure_time) do
      # Validate that departure_time is a parsable date/time
      Time.parse(value)
    rescue StandardError
      key.failure('must be a valid ISO 8601 or RFC 2822 datetime format')
    end
  end
end
