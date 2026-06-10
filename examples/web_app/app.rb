require 'bundler/setup'
Bundler.require(:default, ENV['RACK_ENV'] || :development)

require 'securerandom'
require 'oj'
require 'rack/auth/basic'

# Load the local gem code
$LOAD_PATH.unshift(File.expand_path('../../lib', __dir__))
require 'shadowme'
require_relative 'app/services/admin_view'

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

  # Enable hash branches for route split
  plugin :hash_branches
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
      google_api_ok = ENV.fetch('GOOGLE_MAPS_API_KEY', nil) && !ENV['GOOGLE_MAPS_API_KEY'].strip.empty?

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
      auth = Rack::Auth::Basic::Request.new(r.env)
      if auth.provided? && auth.basic? && auth.credentials == ['admin', ENV['ADMIN_PASSWORD'] || 'admin123']
        response.status = 200
        response['Content-Type'] = 'text/html; charset=utf-8'
        ShadowMe::AdminView.render(api_key: ENV['GOOGLE_MAPS_API_KEY'] || 'test-api-key')
      else
        response.status = 401
        response['WWW-Authenticate'] = 'Basic realm="ShadowMe Admin UI"'
        r.halt(401, 'Unauthorized')
      end
    end

    # Dispatch to branches (e.g. hash_branch('api'))
    r.hash_branches
  end
end

# Require the routes manually as Zeitwerk does not autoload files
# that do not map to matching top-level constant definitions.
Dir["#{__dir__}/app/routes/**/*.rb"].each { |f| require f }
