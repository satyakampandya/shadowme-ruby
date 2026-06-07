require 'dry-validation'
require 'time'

class RecommendationValidator < Dry::Validation::Contract
  params do
    required(:source).filled(:string)
    required(:destination).filled(:string)
    required(:departure_time).filled(:string)
    optional(:route_index).filled(:integer, gteq?: 0)
  end

  rule(:departure_time) do
    begin
      # Validate that departure_time is a parsable date/time
      Time.parse(value)
    rescue
      key.failure('must be a valid ISO 8601 or RFC 2822 datetime format')
    end
  end
end
