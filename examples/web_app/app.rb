require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'securerandom'
require 'oj'

# Load the local gem code
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))
require 'shadowme'
require_relative 'app/views/admin_view'

class App < Roda
  # Wrap the Rack call method to log request details after execution is completed.
  # This guarantees we log the actual finalized HTTP status code (e.g. 200 for assets, 404 for not found).
  def self.call(env)
    env['shadowme.request_id'] = SecureRandom.uuid
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    status, headers, body = super

    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000.0).round

    log_payload = {
      request_id: env['shadowme.request_id'],
      path: env['PATH_INFO'],
      verb: env['REQUEST_METHOD'],
      status: status,
      duration_ms: duration_ms,
      cache_hit: false
    }

    log_payload[:source] = env['shadowme.source'] if env['shadowme.source']
    log_payload[:destination] = env['shadowme.destination'] if env['shadowme.destination']
    log_payload[:error] = env['shadowme.error'] if env['shadowme.error']
    log_payload[:params] = env['shadowme.params'] if env['shadowme.params']

    puts Oj.dump(log_payload, mode: :compat)

    [status, headers, body]
  end

  # Enable parsing of JSON request bodies
  plugin :json_parser
  # Enable halting of requests early
  plugin :halt
  # Serve static files from public directory
  plugin :public, root: File.expand_path('public', __dir__)

  # Enable structured error handling and translate exceptions into standard format without exposing backtraces
  plugin :error_handler do |e|
    env['shadowme.error'] = e.message

    status_code = case e
                  when ShadowMe::ValidationError
                    400
                  when ShadowMe::InvalidRouteError
                    422
                  when ShadowMe::GoogleApiError
                    502
                  else
                    500
                  end

    response.status = status_code
    response['Content-Type'] = 'application/json'

    error_response = if e.is_a?(ShadowMe::ValidationError)
                       { error: e.message, validation_errors: e.errors }
                     elsif e.is_a?(ShadowMe::InvalidRouteError) || e.is_a?(ShadowMe::GoogleApiError)
                       { error: e.message }
                     else
                       # Hide standard/internal exceptions stack trace
                       { error: 'Unable to calculate recommendation' }
                     end

    Oj.dump(error_response, mode: :compat)
  end

  route do |r|
    # Enable CORS for decoupled frontend development
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'

    if r.request_method == 'OPTIONS'
      response.status = 200
      r.halt(200, '')
    end

    # Serve static assets
    r.public

    # Store incoming params in env for logging
    r.env['shadowme.params'] = r.params if r.params && !r.params.empty?

    # 1. Health check endpoint (GET /health)
    r.get 'health' do
      response.status = 200
      response['Content-Type'] = 'application/json'
      Oj.dump({ status: 'ok' }, mode: :compat)
    end

    # 2. Readiness check endpoint (GET /ready)
    r.get 'ready' do
      api_key = ShadowMe.api_key || ENV.fetch('GOOGLE_MAPS_API_KEY', nil)
      google_api_ok = api_key && !api_key.to_s.strip.empty?

      status_code = google_api_ok ? 200 : 503
      response.status = status_code
      response['Content-Type'] = 'application/json'

      Oj.dump({
                status: status_code == 200 ? 'ready' : 'not_ready',
                checks: {
                  google_api: google_api_ok ? 'configured' : 'missing'
                }
              }, mode: :compat)
    end

    # 3. Admin UI (GET /admin)
    r.get 'admin' do
      response.status = 200
      response['Content-Type'] = 'text/html; charset=utf-8'
      ShadowMe::AdminView.render(api_key: ENV['GOOGLE_MAPS_API_KEY'] || 'test-api-key')
    end

    # 4. Recommendation API Route
    r.on 'api' do
      r.on 'v1' do
        r.on 'recommendation' do
          r.post do
            # Extract parameters directly from request (validation will occur inside the gem)
            params = r.params || {}
            source = params['source']
            destination = params['destination']
            departure_time_str = params['departure_time']
            route_index = params['route_index']
            include_steps = params['include_steps']

            # Store logging context in env
            r.env['shadowme.source'] = source
            r.env['shadowme.destination'] = destination

            # Run engine calculations (which validates inputs and coerces types)
            result_hash = ShadowMe.calculate(
              source,
              destination,
              departure_time_str,
              route_index: route_index,
              include_steps: include_steps
            )

            response.status = 200
            response['Content-Type'] = 'application/json'
            Oj.dump(result_hash, mode: :compat)
          end
        end
      end
    end
  end
end
