# ShadowMe Ruby Gem

`shadowme-ruby` is a stateless mathematical calculation engine packaged as a Ruby Gem. It calculates sunlight exposure on a passenger vehicle during a journey to recommend whether a passenger should sit on the **left side** or **right side** to minimize direct sunlight exposure.

The engine parses route geometries from the Google Directions API, calculates vehicle bearings, and computes the sun's relative position (azimuth and elevation) throughout the trip to determine the side receiving the least solar radiation.

---

## 🏗️ Project Architecture

* **`lib/`**: Contains the standalone library code. It has zero dependencies on web servers (Roda/Puma) or databases, making it extremely lightweight and secure for production load in other apps (e.g. Rails API gateway).
* **`examples/web_app/`**: A development-only sandbox containing the Roda API wrapper and the interactive Admin UI dashboard. This is completely excluded from the packaged gem build.

---

## ⚙️ Installation

To use this gem in your Rails or other Ruby projects, add it to your `Gemfile` pointing to the local directory (or git repository):

```ruby
gem 'shadowme-ruby', path: 'path/to/shadowme-ruby'
```

And run:
```bash
bundle install
```

---

## 🚀 Usage

Exposes a clean, public class method entrypoint:

```ruby
require 'shadowme'

result = ShadowMe.calculate(
  "21.1702,72.8311",                # source coordinates
  "23.0225,72.5714",                # destination coordinates
  "2026-06-10T08:00:00+05:30",      # departure time (String or Time)
  route_index: 0,                   # optional route index (default: 0)
  include_steps: true               # optional steps breakdown (default: false)
)
```

### Response Hash Format (Simple)
```ruby
{
  recommended_side: "left",
  left_exposure_minutes: 15,
  right_exposure_minutes: 72,
  night_exposure_minutes: 0,
  front_behind_exposure_minutes: 0,
  confidence: "high",
  message: "You should sit on the left side of the vehicle to minimize direct sunlight exposure."
}
```

---

## 🧪 Running Library Tests

Minitest handles the testing of all calculator and client logic. Upstream Google Directions API calls are completely mocked using WebMock to enable offline testing.

To run the entire unit test suite:
```bash
bundle exec rake
```

---

## 🛠️ Local Interactive Sandbox (Web UI & API)

We provide a web-based sandbox dashboard under `examples/web_app` to test the calculations visually on a map.

For instructions on configuring and running the web sandbox locally, refer to the [Web Sandbox README](file:///Users/satyakampandya/workspace/shadowme-ruby/examples/web_app/README.md).
