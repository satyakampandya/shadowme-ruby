require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'securerandom'
require 'zeitwerk'
require 'oj'
require 'rack/auth/basic'

# Setup Zeitwerk autoloader to load the core parts of the application
loader = Zeitwerk::Loader.new

# Push subdirectories so their contents are loaded at the top-level namespace
loader.push_dir("#{__dir__}/app/errors")
loader.push_dir("#{__dir__}/app/models")
loader.push_dir("#{__dir__}/app/clients")
loader.push_dir("#{__dir__}/app/validators")
loader.push_dir("#{__dir__}/app/serializers")
loader.push_dir("#{__dir__}/app/services")

loader.setup

class App < Roda
  # Enable hash branches for route split
  plugin :hash_branches
  # Enable parsing of JSON request bodies
  plugin :json_parser
  # Enable halting of requests early
  plugin :halt
  # Enable structured error handling and translate exceptions into standard format without exposing backtraces
  plugin :error_handler do |e|
    @error = e.message

    status_code = case e
                  when ValidationError
                    400
                  when InvalidRouteError
                    422
                  when GoogleApiError
                    502
                  else
                    500
                  end

    response.status = status_code
    response['Content-Type'] = 'application/json'

    error_response = if e.is_a?(ValidationError)
                       { error: e.message, validation_errors: e.errors }
                     elsif e.is_a?(InvalidRouteError) || e.is_a?(GoogleApiError)
                       { error: e.message }
                     else
                       # Hide standard/internal exceptions stack trace
                       { error: "Unable to calculate recommendation" }
                     end

    Oj.dump(error_response, mode: :compat)
  end

  route do |r|
    @request_id = SecureRandom.uuid
    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @source = nil
    @destination = nil
    @error = nil
    @cache_hit = false

    begin
      # 1. Health check endpoint (GET /health)
      r.get 'health' do
        response.status = 200
        response['Content-Type'] = 'application/json'
        Oj.dump({ status: 'ok' }, mode: :compat)
      end

      # 2. Readiness check endpoint (GET /ready)
      r.get 'ready' do
        redis_ok = !TripCache.redis_client.nil?
        google_api_ok = ENV['GOOGLE_MAPS_API_KEY'] && !ENV['GOOGLE_MAPS_API_KEY'].strip.empty?

        status_code = (redis_ok && google_api_ok) ? 200 : 503
        response.status = status_code
        response['Content-Type'] = 'application/json'

        Oj.dump({
          status: status_code == 200 ? 'ready' : 'not_ready',
          checks: {
            redis: redis_ok ? 'ok' : 'failed',
            google_api: google_api_ok ? 'configured' : 'missing'
          }
        }, mode: :compat)
      end

      # 3. Admin UI (GET /admin)
      r.get 'admin' do
        auth = Rack::Auth::Basic::Request.new(r.env)
        if auth.provided? && auth.basic? && auth.credentials == ['admin', ENV['ADMIN_PASSWORD'] || 'admin123']
          response.status = 200
          response['Content-Type'] = 'text/html; charset=utf-8'
          AdminView.render(api_key: ENV['GOOGLE_MAPS_API_KEY'] || 'test-api-key')
        else
          response.status = 401
          response['WWW-Authenticate'] = 'Basic realm="ShadowMe Admin UI"'
          r.halt(401, 'Unauthorized')
        end
      end

      # Dispatch to branches (e.g. hash_branch('api'))
      r.hash_branches
    rescue => e
      @error = e.message
      response.status = case e
                        when ValidationError
                          400
                        when InvalidRouteError
                          422
                        when GoogleApiError
                          502
                        else
                          500
                        end
      raise e
    ensure
      # Structured JSON Logging
      duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time) * 1000.0).round

      log_payload = {
        request_id: @request_id,
        path: r.path,
        verb: r.request_method,
        status: response.status || 404,
        duration_ms: duration_ms,
        cache_hit: @cache_hit
      }

      log_payload[:source] = @source if @source
      log_payload[:destination] = @destination if @destination
      log_payload[:error] = @error if @error
      log_payload[:params] = r.params if r.params && !r.params.empty?

      puts Oj.dump(log_payload, mode: :compat)
    end
  end
end

# Require the routes manually as Zeitwerk does not autoload files 
# that do not map to matching top-level constant definitions.
Dir["#{__dir__}/app/routes/**/*.rb"].each { |f| require f }
