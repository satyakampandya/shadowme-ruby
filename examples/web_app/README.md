# ShadowMe Local Web Sandbox

This directory contains a local, interactive web application sandbox built with **Roda** and **Puma**. It serves as a playground and reference implementation for the namespaced `ShadowMe` calculation engine.

> [!NOTE]
> All web server dependencies (Roda, Puma, Rackup) and static assets in this directory are excluded from the production package of the `shadowme-ruby` gem. They are loaded strictly during local development and testing.

---

## 🚀 How to Run the Web Sandbox

Make sure you have configured your environment variables first (e.g. `GOOGLE_MAPS_API_KEY`).

Run the web application sandbox from the project root using `rackup`:
```bash
bundle exec rackup examples/web_app/config.ru -p 9292
```

---

## 🗺️ Key Endpoints & UI

### 1. Interactive Admin UI Dashboard
* **URL**: `GET http://localhost:9292/admin`
* **Credentials**: Username: `admin` | Password: `admin123` (or configured via `ADMIN_PASSWORD` env var).
* **Features**: Includes location autocomplete, route comparisons, and a playable route-bearing simulation.

### 2. Recommendation API
* **URL**: `POST http://localhost:9292/api/v1/recommendation`
* **Payload**:
  ```json
  {
    "source": "21.1702,72.8311",
    "destination": "23.0225,72.5714",
    "departure_time": "2026-06-10T08:00:00+05:30",
    "include_steps": true
  }
  ```

### 3. Monitoring
* **Health Check**: `GET http://localhost:9292/health`
* **Readiness Check**: `GET http://localhost:9292/ready` (verifies Google API key is configured).

---

## 🧪 Running Sandbox Integration Tests

Execute the Rack-Test integration specs from the root directory:
```bash
# Run API endpoints tests
bundle exec ruby -I"lib:examples/web_app" examples/web_app/test/api_endpoints_test.rb

# Run Admin UI tests
bundle exec ruby -I"lib:examples/web_app" examples/web_app/test/admin_view_test.rb
```
