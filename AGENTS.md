# ShadowMe API - Technical Guidelines

## General Agent Rules

* **Commit Constraints**: Never auto-commit anything, and never suggest, offer, or ask to commit changes. The user will explicitly state when a commit is needed.
* **Ponytail Mode**: Always follow the Ponytail "lazy senior developer" philosophy:
  1. Does this need to be built at all? (YAGNI - skip if not required).
  2. Does the standard library already do this? Use it.
  3. Does a native platform feature cover it? Use it.
  4. Does an already-installed dependency solve it? Use it.
  5. Can this be one line? Make it one line.
  6. Only then: write the minimum code that works.
  Rules:
  - No abstractions that weren't explicitly requested.
  - No new dependency if it can be avoided.
  - No boilerplate nobody asked for.
  - Deletion over addition. Boring over clever. Fewest files possible.
  - Question complex requests: "Do you actually need X, or does Y cover it?"
  - Pick the edge-case-correct option when two stdlib approaches are the same size.
  - Mark intentional simplifications with a `// ponytail:` (or `# ponytail:`) comment.

## Objective

Build a lightweight Ruby library (gem) and a local development sandbox service that recommends whether a passenger should sit on the **left side** or **right side** of a vehicle to minimize direct sunlight exposure during a journey.

The system analyzes the route returned by Google Directions API, calculates the sun's position throughout the journey, and determines which side receives less sunlight.

---

# Tech Stack

### Standalone Ruby Gem (`lib/`)
* Ruby 3.4+
* Faraday (with configured connection/read timeouts)
* Zeitwerk (namespace autoloading & class collapse configuration)
* Dry-Validation (input schema validation)
* Oj (fast JSON processing)
* Minitest (unit testing)

*Note: No database or caching dependencies are included in the production gem package to ensure a completely stateless calculation engine.*

### Local Development Sandbox (`examples/web_app/`)
* Roda (routing tree web framework)
* Puma (rack web server)
* Rackup
* HTML, CSS, JavaScript (Admin UI dashboard)
* Rack::Test (integration testing)

---

# API Design (Sandbox Web App)

## Endpoint

```http
POST /api/v1/recommendation
```

## Request

```json
{
  "source": "21.1702,72.8311",
  "destination": "23.0225,72.5714",
  "departure_time": "2026-06-10T08:00:00+05:30",
  "include_steps": false
}
```

## Response (Daytime Trip - Simple / Default)

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

## Response (Daytime Trip - Detailed with `include_steps: true`)

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
  ]
}
```

## Response (Night-time Trip Example)

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

# Architecture

```text
Web Sandbox (examples/web_app/)             Standalone Gem (lib/shadowme/)
┌──────────────────────────────┐            ┌────────────────────────────────┐
│ Roda API & Admin UI Dashboard│            │ ShadowMe.calculate             │
│                              │            │                                │
│ - app.rb (Roda application)  │            │ - TripAnalyzerService          │
│ - AdminView (HTML Renderer)  │ ─────────> │ - RouteAnalyzerService         │
│ - RecommendationValidator    │            │ - StepAnalyzerService          │
│                              │            │ - Bearing/Midpoint Calculators │
│ - Public Static Assets       │            │ - SunPositionService           │
└──────────────────────────────┘            └────────────────────────────────┘
```

---

# Project Structure

```text
shadowme-ruby/

├── lib/
│   ├── shadowme.rb
│   └── shadowme/
│       ├── clients/
│       │   └── google_maps_client.rb
│       ├── errors/
│       │   ├── google_api_error.rb
│       │   ├── invalid_route_error.rb
│       │   ├── sun_calculation_error.rb
│       │   └── validation_error.rb
│       ├── models/
│       │   ├── route_step.rb
│       │   ├── seat_recommendation.rb
│       │   ├── sun_position.rb
│       │   └── trip_request.rb
│       ├── serializers/
│       │   └── recommendation_serializer.rb
│       ├── services/
│       │   ├── bearing_calculator.rb
│       │   ├── google_directions_route_mapper.rb
│       │   ├── midpoint_calculator.rb
│       │   ├── polyline_decoder.rb
│       │   ├── relative_sun_position_service.rb
│       │   ├── route_analyzer_service.rb
│       │   ├── route_step_segmenter.rb
│       │   ├── seat_recommendation_service.rb
│       │   ├── step_analyzer_service.rb
│       │   ├── sun_position_service.rb
│       │   └── trip_analyzer_service.rb
│       └── validators/
│           └── recommendation_validator.rb
│
├── examples/
│   └── web_app/
│       ├── app.rb
│       ├── config.ru
│       ├── README.md
│       ├── config/
│       │   └── puma.rb
│       ├── app/
│       │   └── views/
│       │       ├── admin.html.erb
│       │       └── admin_view.rb
│       ├── public/
│       │   ├── css/
│       │   └── js/
│       └── test/
│           ├── admin_view_test.rb
│           └── api_endpoints_test.rb
│
├── test/
│   ├── test_helper.rb
│   └── unit/
│       ├── bearing_calculator_test.rb
│       ├── google_maps_client_test.rb
│       └── ...
│
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── shadowme-ruby.gemspec
└── AGENTS.md
```

---

# Route Processing Strategy

The system must not evaluate only the overall route.

Google Directions returns:

```text
Route
  └── Legs
       └── Steps
```

The system must process every step individually because vehicle heading changes throughout the journey.

Example:

```text
Step 1
Heading East

Step 2
Heading South

Step 3
Heading West
```

Sun exposure changes accordingly.

---

# Step Analysis Algorithm

For every step returned by Google Directions:

## 1. Determine Step Midpoint Location

Input:

```text
Start Lat/Lng
End Lat/Lng
```

Calculate:

```ruby
mid_lat = (start_lat + end_lat) / 2.0
mid_lng = (start_lng + end_lng) / 2.0
```

---

## 2. Determine Step Midpoint Time

Example:

```text
Trip Start Time: 08:00

Step Duration: 10 minutes
```

Evaluate sun position at:

```text
08:05
```

(midpoint of step)

---

## 3. Determine Vehicle Bearing

Calculate heading from:

```text
Step Start Location
→
Step End Location
```

Example:

```text
0°   = North
90°  = East
180° = South
270° = West
```

---

## 4. Calculate Sun Position

Input:

```ruby
latitude
longitude
datetime
```

Output:

```ruby
{
  azimuth: 110.5,
  elevation: 42.3
}
```

The implementation calculates this locally using astronomy formulas (via the `sun_calc` gem).

Do not use external sun-position APIs.

---

## 5. Determine Sun Side Relative to Vehicle

Inputs:

```ruby
vehicle_bearing
sun_azimuth
```

Calculate:

```ruby
delta = (sun_azimuth - vehicle_bearing) % 360
```

Interpretation:

```text
0°     = directly ahead
180°   = directly behind

0-180°     => right side
180-360°   => left side
```

Output:

```ruby
:left
:right
:front
:behind
```

---

## 6. Accumulate Exposure

Maintain:

```ruby
left_exposure_seconds
right_exposure_seconds
```

Example:

```ruby
if sun_side == :left
  left_exposure_seconds += step_duration
elsif sun_side == :right
  right_exposure_seconds += step_duration
end
```

---

# Recommendation Logic

After all steps are processed:

```ruby
if left_exposure_seconds < right_exposure_seconds
  recommended_side = :left
else
  recommended_side = :right
end
```

The recommended side is the side receiving less sunlight.

---

# Confidence Calculation

Calculate exposure difference percentage.

Example:

```text
0-10%      => low
10-30%     => medium
30%+       => high
```

Response:

```json
{
  "recommended_side": "left",
  "confidence": "high"
}
```

---

# Google Maps Integration

Create a dedicated client under the `ShadowMe` namespace.

```ruby
module ShadowMe
  class GoogleMapsClient
    def directions(...)
    end
  end
end
```

Only this class should communicate with Google APIs. It enforces connection (2s) and read (5s) timeouts on its Faraday connection.

No other service should know Google-specific details.

---

# Caching (Removed)

V1 does not perform caching. The application remains completely stateless.

---

# Error Handling

All custom exceptions are namespaced under the `ShadowMe` module.

```ruby
ShadowMe::GoogleApiError
ShadowMe::InvalidRouteError
ShadowMe::SunCalculationError
ShadowMe::ValidationError
```

API responses should never expose stack traces.

Example:

```json
{
  "error": "Unable to calculate recommendation"
}
```

---

# Logging

Use structured JSON logs on stdout (handled at the Rack level inside `App.call`).

Example:

```json
{
  "request_id": "...",
  "source": "21.1702,72.8311",
  "destination": "23.0225,72.5714",
  "duration_ms": 152
}
```

---

# Health Checks

```http
GET /health
```

Response:

```json
{
  "status": "ok"
}
```

Ready check endpoint:

```http
GET /ready
```

Checks:
* Google API configuration key presence

---

# Testing Strategy

### Unit Tests (`test/unit/`)
Test calculation services, calculators, and clients independently:
* `BearingCalculator`
* `GoogleDirectionsRouteMapper`
* `GoogleMapsClient` (with mocked API calls using WebMock)
* `MidpointCalculator`
* `RelativeSunPositionService`
* `RouteStepSegmenter`
* `SeatRecommendationService`
* `SunPositionService`

### Integration Tests (`examples/web_app/test/`)
Test Rack integration endpoints and the Admin view HTML rendering:
* `ApiEndpointsTest`
* `AdminViewTest`

---

# Core Principle

The service remains a **stateless computation engine** wrapped in a standalone gem:

```text
Input: Source, Destination, Departure Time

↓

Google Directions Route

↓

Analyze Every Step (Midpoints & Bearing)

↓

Calculate Sun Position

↓

Measure Left/Right Exposure

↓

Return Seat Recommendation
```

Keep the library decoupled from web UI/dashboard components, and keep business logic isolated in testable service objects.
