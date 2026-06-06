class ValidationError < StandardError
  attr_reader :errors

  def initialize(message = "Validation failed", errors = {})
    super(message)
    @errors = errors
  end
end
