# ShadowMe API - Technical Guidelines

## General Agent Rules

* **Commit Constraints**: Never try to auto-commit anything after a task completion on your own. Only commit when explicitly asked by the user.

## Objective

Build a lightweight Ruby API service that recommends whether a passenger should sit on the **left side** or **right side** of a vehicle to minimize direct sunlight exposure during a journey.

The system should analyze the route returned by Google Directions API, calculate the sun's position throughout the journey, and determine which side receives less sunlight.

---

# Tech Stack

```text
Ruby 3.4+
Roda
Puma
Faraday
Zeitwerk
Dry-Validation
Oj
Redis (optional, recommended)
Docker
Minitest
```

No database is required for V1.

The application should remain completely stateless.

---

# API Design

## Endpoint

```http
POST /api/v1/recommendation
```

## Request

```json
{
  "source": "21.1702,72.8311",
  "destination": "23.0225,72.5714",
  "departure_time": "2026-06-10T08:00:00+05:30"
}
```

## Response (Daytime Trip Example)

```json
{
  "recommended_side": "left",
  "left_exposure_minutes": 15,
  "right_exposure_minutes": 72,
  "confidence": "high",
  "message": "You should sit on the left side of the vehicle to minimize direct sunlight exposure."
}
```

## Response (Night-time Trip Example)

```json
{
  "recommended_side": "either",
  "left_exposure_minutes": 0,
  "right_exposure_minutes": 0,
  "confidence": "high",
  "message": "It is night time, enjoy your journey!"
}
```

---

# Architecture

```text
Client
  │
  ▼
Roda API
  │
  ▼
Request Validator
  │
  ▼
TripAnalyzerService
  │
  ├── GoogleMapsClient
  │
  ├── RouteAnalyzerService
  │
  ├── SunPositionService
  │
  ├── RelativeSunPositionService
  │
  └── SeatRecommendationService
```

---

# Project Structure

```text
shadowme-ruby/

├── app.rb
├── config.ru
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── Dockerfile
├── docker-compose.yml

├── app/
│   ├── routes/
│   │   └── recommendation_route.rb
│   │
│   ├── clients/
│   │   └── google_maps_client.rb
│   │
│   ├── services/
│   │   ├── trip_analyzer_service.rb
│   │   ├── route_analyzer_service.rb
│   │   ├── step_analyzer_service.rb
│   │   ├── bearing_calculator.rb
│   │   ├── midpoint_calculator.rb
│   │   ├── sun_position_service.rb
│   │   ├── relative_sun_position_service.rb
│   │   ├── seat_recommendation_service.rb
│   │   └── trip_cache.rb
│   │
│   ├── validators/
│   │   └── recommendation_validator.rb
│   │
│   ├── serializers/
│   │   └── recommendation_serializer.rb
│   │
│   ├── models/
│   │   ├── trip_request.rb
│   │   ├── route_step.rb
│   │   ├── sun_position.rb
│   │   └── seat_recommendation.rb
│   │
│   └── errors/
│       ├── google_api_error.rb
│       ├── invalid_route_error.rb
│       ├── sun_calculation_error.rb
│       └── validation_error.rb
│
├── config/
│   └── puma.rb
│
└── test/
    ├── test_helper.rb
    ├── unit/
    └── integration/
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

The implementation should calculate this locally using astronomy formulas or a Ruby library.

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

Create a dedicated client.

```ruby
class GoogleMapsClient
  def directions(...)
  end
end
```

Only this class should communicate with Google APIs.

No other service should know Google-specific details.

---

# Caching

Use Redis.

Cache key:

```text
source
destination
departure_time
```

Example:

```ruby
Digest::SHA256.hexdigest(...)
```

TTL:

```text
6 hours
```

or

```text
24 hours
```

depending on traffic sensitivity.

---

# Error Handling

Create custom exceptions.

```ruby
GoogleApiError
InvalidRouteError
SunCalculationError
ValidationError
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

Use structured JSON logs.

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

Optional readiness endpoint:

```http
GET /ready
```

Checks:

```text
* Redis connectivity
* Google API configuration
```

---

# Testing Strategy

### Unit Tests

Test independently:

```text
BearingCalculator
MidpointCalculator
SunPositionService
RelativeSunPositionService
SeatRecommendationService
```

### Integration Tests

Test:

```text
GoogleMapsClient
API Endpoints
TripAnalyzerService
```

Google API calls should be mocked during tests.

---

# Future Enhancements (Not V1)

* Polyline-based route analysis instead of step-based analysis
* Traffic-aware calculations
* Route alternatives comparison
* User accounts
* API keys and billing
* PostgreSQL analytics storage
* Historical recommendation tracking
* Multi-stop journeys
* Weather/cloud cover integration

---

# Core Principle

The service should remain a **stateless computation engine**:

```text
Input:
Source
Destination
Departure Time

↓

Google Directions Route

↓

Analyze Every Step

↓

Calculate Sun Position

↓

Measure Left/Right Exposure

↓

Return Seat Recommendation
```

Avoid Rails, avoid a database, and keep all business logic isolated into small, testable service objects. This keeps the codebase lightweight, fast, inexpensive to operate, and easy to maintain.
