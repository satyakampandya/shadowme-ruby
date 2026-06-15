# ponytail: defined custom exceptions in a single file to reduce boilerplate and file count.
module ShadowMe
  class GoogleApiError < StandardError; end
  class InvalidRouteError < StandardError; end
  class SunCalculationError < StandardError; end

  class ValidationError < StandardError
    attr_reader :errors

    def initialize(message = 'Validation failed', errors = {})
      super(message)
      @errors = errors
    end
  end
end
