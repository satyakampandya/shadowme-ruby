# ShadowMe API

ShadowMe is a lightweight, stateless Ruby microservice that recommends whether a passenger should sit on the **left side** or **right side** of a vehicle during a journey to minimize direct sunlight exposure.

By analyzing Google Directions API route steps, the system calculates the vehicle's bearing and the sun's relative position (azimuth and elevation) throughout the trip to determine the side receiving the least solar radiation.

---

## Technical Stack
- **Runtime**: Ruby 3.4+
- **Routing**: Roda
- **App Server**: Puma
- **HTTP Client**: Faraday
- **Autoloading**: Zeitwerk
- **Validation**: Dry-Validation
- **JSON Engine**: Oj
- **Cache Store**: Redis
- **Testing**: Minitest, WebMock, Rack-Test
- **Containerization**: Docker & Docker Compose

---

## Project Structure
```text
shadowme-ruby/
├── app.rb                   # App entrypoint (autoloading, logging, error handler)
├── config.ru                # Rackup configuration
├── Rakefile                 # Rake tasks (testing)
├── Dockerfile               # Production Docker container definition
├── docker-compose.yml       # Multi-container local orchestration
├── config/
│   └── puma.rb              # Puma server configuration
├── app/
│   ├── clients/             # External client integrations (Google Maps)
│   ├── errors/              # Custom exceptions
│   ├── models/              # Pure Ruby data models
│   ├── routes/              # Routing branches (Roda hash branches)
│   ├── serializers/         # JSON serializing logic (Oj)
│   ├── services/            # Core business logic, calculators, and caching
│   └── validators/          # Input schema contracts (Dry-Validation)
└── test/
    ├── test_helper.rb       # Test configuration and stubs
    ├── unit/                # Service/Calculator tests
    └── integration/         # API Endpoint and client tests
```

---

## Getting Started

### Prerequisites
- **Ruby**: version `3.4.0` or higher
- **Bundler**: installed (`gem install bundler`)
- **Redis**: installed and running locally (optional, but recommended for caching)
- **Google Maps API Key**: Directions API enabled

### Local Installation
1. Clone the repository and navigate to the directory:
   ```bash
   cd shadowme-ruby
   ```

2. Install the gems:
   ```bash
   bundle install
   ```

3. Set up environment variables. Create a `.env` file or export them directly in your shell:
   ```bash
   export GOOGLE_MAPS_API_KEY="your-google-maps-api-key-here"
   export REDIS_URL="redis://127.0.0.1:6379/0" # Optional
   ```

### Running Locally
To launch the server locally on the default port `9292` using Puma:
```bash
bundle exec puma config.ru
```
The server will now be accessible at `http://localhost:9292`.

---

## API Endpoints

### 1. Health Check
Checks if the web server is responsive.
- **URL**: `/health`
- **Method**: `GET`
- **Response**:
  ```json
  {
    "status": "ok"
  }
  ```

### 2. Readiness Check
Checks system dependencies (Redis connectivity and Google API environment variables).
- **URL**: `/ready`
- **Method**: `GET`
- **Response (Success - 200 OK)**:
  ```json
  {
    "status": "ready",
    "checks": {
      "redis": "ok",
      "google_api": "configured"
    }
  }
  ```
- **Response (Failure - 503 Service Unavailable)**:
  ```json
  {
    "status": "not_ready",
    "checks": {
      "redis": "failed",
      "google_api": "missing"
    }
  }
  ```

### 3. Get Seat Recommendation
Calculates the optimal side to sit on. By default, internal debug steps and route geometries are omitted from the response to optimize payload size and cache memory. To request detailed route step coordinates, bearings, and sun positions, set `"include_steps": true`.

- **URL**: `/api/v1/recommendation`
- **Method**: `POST`
- **Headers**: `Content-Type: application/json`
- **Payload**:
  ```json
  {
    "source": "21.1702,72.8311",
    "destination": "23.0225,72.5714",
    "departure_time": "2026-06-10T08:00:00+05:30",
    "include_steps": false,
    "route_index": 0
  }
  ```
- **Response (200 OK - Default/Simple Response)**:
  ```json
  {
    "recommended_side": "left",
    "left_exposure_minutes": 15,
    "right_exposure_minutes": 72,
    "night_exposure_minutes": 0,
    "front_behind_exposure_minutes": 0,
    "confidence": "high",
    "message": "You should sit on the left side of the vehicle to minimize direct sunlight exposure."
  }
  ```

- **Response (200 OK - With Detailed Steps `include_steps: true`)**:
  ```json
  {
    "recommended_side": "left",
    "left_exposure_minutes": 15,
    "right_exposure_minutes": 72,
    "night_exposure_minutes": 0,
    "front_behind_exposure_minutes": 0,
    "confidence": "high",
    "message": "You should sit on the left side of the vehicle to minimize direct sunlight exposure.",
    "steps": [
      {
        "start_lat": 21.1702,
        "start_lng": 72.8311,
        "end_lat": 21.2015,
        "end_lng": 72.8532,
        "duration": 600,
        "distance": 5000,
        "midpoint_lat": 21.18585,
        "midpoint_lng": 72.84215,
        "midpoint_time": "2026-06-10T08:05:00+05:30",
        "bearing": 30.5,
        "sun_azimuth": 110.5,
        "sun_elevation": 42.3,
        "sun_side": "right"
      }
    ],
    "route_index": 0
  }
  ```

- **Response (200 OK - Night-time Trip)**:
  ```json
  {
    "recommended_side": "either",
    "left_exposure_minutes": 0,
    "right_exposure_minutes": 0,
    "night_exposure_minutes": 180,
    "front_behind_exposure_minutes": 0,
    "confidence": "high",
    "message": "It is night time, enjoy your journey!"
  }
  ```

---

## Running Tests
Minitest handles the testing. Upstream Google Directions API calls are completely mocked using WebMock, and Redis is stubbed by default in tests to enable offline testing.

To run the entire test suite:
```bash
bundle exec rake test
```
Alternatively, you can run all tests using the Ruby interpreter directly:
```bash
bundle exec ruby -e "Dir['test/**/*_test.rb'].each { |f| require File.expand_path(f) }"
```

---

## Running with Docker

### Using Docker Compose (Recommended)
Docker Compose will launch both the web application (port `9292`) and a local Redis instance:

1. Launch services:
   ```bash
   GOOGLE_MAPS_API_KEY="your_api_key" docker-compose up --build
   ```

2. Stop services:
   ```bash
   docker-compose down
   ```

### Using Docker Directly
1. Build the Docker image:
   ```bash
   docker build -t shadowme-api .
   ```

2. Run the container:
   ```bash
   docker run -p 9292:9292 -e GOOGLE_MAPS_API_KEY="your_api_key" shadowme-api
   ```

---

## Deployment & Production Configurations
- **App Freezing**: When running in production (`RACK_ENV=production`), Roda routes are frozen for optimal performance.
- **Thread Concurrency**: Puma can be scaled concurrently by setting `MAX_THREADS` and `WEB_CONCURRENCY` environment variables.
- **API Cache**: Caching defaults to a **24-hour TTL**. Ensure your production deployment sets `REDIS_URL` to point to a persistent/elastic Redis store.
