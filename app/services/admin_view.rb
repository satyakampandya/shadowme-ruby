class AdminView
  def self.render(api_key:)
    <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ShadowMe Admin Portal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-color: #0b0f19;
      --card-bg: #151d30;
      --card-border: #222f4c;
      --text-color: #f8fafc;
      --text-muted: #94a3b8;
      --accent-primary: #6366f1;
      --accent-secondary: #a855f7;
      --left-side-glow: rgba(59, 130, 246, 0.15);
      --right-side-glow: rgba(236, 72, 153, 0.15);
      --input-bg: #0f1524;
      --input-border: #2b3a5a;
      --success-color: #10b981;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Inter', sans-serif;
    }

    body {
      background-color: var(--bg-color);
      color: var(--text-color);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 2rem 1.5rem;
      background-image: 
        radial-gradient(circle at 10% 20%, rgba(99, 102, 241, 0.04) 0%, transparent 40%),
        radial-gradient(circle at 90% 80%, rgba(168, 85, 247, 0.04) 0%, transparent 40%);
    }

    header {
      width: 100%;
      max-width: 1200px;
      margin-bottom: 2rem;
      text-align: left;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .header-title h1 {
      font-size: 2rem;
      font-weight: 700;
      background: linear-gradient(135deg, #a5b4fc 0%, #c084fc 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      letter-spacing: -0.025em;
    }

    .header-title p {
      color: var(--text-muted);
      font-size: 0.9rem;
      margin-top: 0.15rem;
    }

    .container {
      width: 100%;
      max-width: 1200px;
      display: grid;
      grid-template-columns: 460px 1fr;
      gap: 2rem;
      align-items: stretch;
    }

    @media (max-width: 1024px) {
      .container {
        grid-template-columns: 1fr;
      }
    }

    .left-column {
      display: flex;
      flex-direction: column;
      gap: 1.5rem;
    }

    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 1.75rem;
      box-shadow: 0 10px 30px -10px rgba(0, 0, 0, 0.5);
      backdrop-filter: blur(10px);
    }

    .map-card {
      display: flex;
      flex-direction: column;
      padding: 0;
      overflow: hidden;
      min-height: 600px;
      height: 100%;
    }

    #map {
      width: 100%;
      height: 100%;
      min-height: 600px;
      background-color: #0f172a;
    }

    .form-group {
      margin-bottom: 1.25rem;
      position: relative;
    }

    label {
      display: block;
      color: var(--text-muted);
      font-size: 0.75rem;
      font-weight: 600;
      margin-bottom: 0.4rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    input[type="text"],
    input[type="datetime-local"] {
      width: 100%;
      background-color: var(--input-bg);
      border: 1px solid var(--input-border);
      border-radius: 8px;
      padding: 0.8rem 1rem;
      color: var(--text-color);
      font-size: 0.95rem;
      outline: none;
      transition: all 0.3s ease;
    }

    input[type="text"]:focus,
    input[type="datetime-local"]:focus {
      border-color: var(--accent-primary);
      box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.25);
    }

    .coords-indicator {
      font-size: 0.75rem;
      color: var(--accent-primary);
      margin-top: 0.35rem;
      display: block;
      font-family: monospace;
      opacity: 0;
      transition: opacity 0.3s ease;
    }

    .coords-indicator.visible {
      opacity: 1;
    }

    button.btn-submit {
      width: 100%;
      background: linear-gradient(135deg, var(--accent-primary) 0%, var(--accent-secondary) 100%);
      color: white;
      border: none;
      border-radius: 8px;
      padding: 0.9rem;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 4px 14px rgba(99, 102, 241, 0.3);
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 0.5rem;
    }

    button.btn-submit:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(99, 102, 241, 0.5);
    }

    button.btn-submit:active {
      transform: translateY(1px);
    }

    button.btn-submit:disabled {
      background: var(--input-border);
      cursor: not-allowed;
      box-shadow: none;
      transform: none;
    }

    /* Result Panel Styling */
    .result-panel {
      min-height: 250px;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      text-align: center;
    }

    .placeholder-state {
      color: var(--text-muted);
    }

    .placeholder-icon {
      font-size: 3rem;
      margin-bottom: 0.75rem;
      opacity: 0.3;
    }

    .result-content {
      width: 100%;
      display: none;
      animation: fadeIn 0.4s ease-out forwards;
    }

    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(8px); }
      to { opacity: 1; transform: translateY(0); }
    }

    .recommendation-badge {
      font-size: 1.25rem;
      font-weight: 700;
      text-transform: uppercase;
      padding: 0.6rem 1.75rem;
      border-radius: 50px;
      display: inline-block;
      margin-bottom: 1.25rem;
    }

    .recommendation-badge.left {
      background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
      color: #fff;
      box-shadow: 0 0 20px rgba(59, 130, 246, 0.3);
    }

    .recommendation-badge.right {
      background: linear-gradient(135deg, #ec4899 0%, #be185d 100%);
      color: #fff;
      box-shadow: 0 0 20px rgba(236, 72, 153, 0.3);
    }

    .recommendation-badge.either {
      background: linear-gradient(135deg, #10b981 0%, #047857 100%);
      color: #fff;
      box-shadow: 0 0 20px rgba(16, 185, 129, 0.3);
    }

    .result-message {
      font-size: 0.975rem;
      line-height: 1.5;
      margin-bottom: 1.75rem;
      color: #e2e8f0;
    }

    .exposure-breakdown {
      width: 100%;
      background: var(--input-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 1.1rem;
      margin-bottom: 1.25rem;
    }

    .exposure-labels {
      display: flex;
      justify-content: space-between;
      margin-bottom: 0.6rem;
      font-size: 0.85rem;
    }

    .lbl-left {
      color: #3b82f6;
      font-weight: 600;
    }

    .lbl-right {
      color: #ec4899;
      font-weight: 600;
    }

    .exposure-bar-container {
      width: 100%;
      height: 10px;
      background-color: var(--card-border);
      border-radius: 5px;
      overflow: hidden;
      display: flex;
    }

    .bar-left {
      height: 100%;
      background-color: #3b82f6;
      transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .bar-right {
      height: 100%;
      background-color: #ec4899;
      transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .bar-neutral {
      height: 100%;
      background-color: #10b981;
      width: 0%;
      transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .details-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.75rem;
      width: 100%;
    }

    .detail-card {
      background: var(--input-bg);
      border: 1px solid var(--card-border);
      border-radius: 8px;
      padding: 0.75rem;
      text-align: left;
    }

    .detail-val {
      font-size: 1.1rem;
      font-weight: 700;
      margin-top: 0.15rem;
      text-transform: capitalize;
    }

    .detail-val.conf-high { color: var(--success-color); }
    .detail-val.conf-medium { color: #f59e0b; }
    .detail-val.conf-low { color: #ef4444; }

    /* Loading Spinner */
    .spinner {
      border: 2px solid rgba(255, 255, 255, 0.1);
      width: 18px;
      height: 18px;
      border-radius: 50%;
      border-left-color: white;
      animation: spin 0.8s linear infinite;
      display: none;
    }

    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    /* Autocomplete container styles */
    .pac-container {
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-top: none;
      border-radius: 0 0 8px 8px;
      font-family: 'Inter', sans-serif;
      box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
    }
    .pac-item {
      border-top: 1px solid var(--card-border);
      padding: 8px 12px;
      color: var(--text-color);
      cursor: pointer;
    }
    .pac-item:hover {
      background-color: var(--input-bg);
    }
    .pac-item-query {
      color: var(--text-color);
      font-size: 0.95rem;
    }
    .pac-matched {
      color: var(--accent-primary);
      font-weight: 600;
    }
    .pac-icon {
      display: none;
    }
  </style>
</head>
<body>

  <header>
    <div class="header-title">
      <h1>ShadowMe Portal</h1>
      <p>Interactive testing panel for sun exposure calculations</p>
    </div>
  </header>

  <div class="container">
    <div class="left-column">
      <!-- Card 1: Form Inputs -->
      <div class="card">
        <form id="recommendation-form" onsubmit="event.preventDefault(); submitForm();">
          <div class="form-group">
            <label for="source-input">Source Location</label>
            <input type="text" id="source-input" placeholder="Search origin location..." required autocomplete="off">
            <input type="hidden" id="source-coords">
            <span id="source-coords-lbl" class="coords-indicator">Coordinates: 0.000, 0.000</span>
          </div>

          <div class="form-group">
            <label for="dest-input">Destination Location</label>
            <input type="text" id="dest-input" placeholder="Search destination location..." required autocomplete="off">
            <input type="hidden" id="dest-coords">
            <span id="dest-coords-lbl" class="coords-indicator">Coordinates: 0.000, 0.000</span>
          </div>

          <div class="form-group">
            <label for="departure-input">Departure Date & Time</label>
            <input type="datetime-local" id="departure-input" required>
          </div>

          <button type="submit" id="submit-btn" class="btn-submit" disabled>
            <span id="btn-text">ShadowMe</span>
            <div id="btn-spinner" class="spinner"></div>
          </button>
        </form>
      </div>

      <!-- Card 2: Results Display -->
      <div class="card result-panel" id="result-panel">
        <div id="placeholder-state" class="placeholder-state">
          <div class="placeholder-icon">☀️</div>
          <h3>Recommendation Insights</h3>
          <p style="color: var(--text-muted); margin-top: 0.5rem; font-size: 0.85rem; padding: 0 1rem;">
            Submit your journey to view the recommended side of the vehicle and direct sunlight exposure times.
          </p>
        </div>

        <div id="result-content" class="result-content">
          <div id="badge-container">
            <span class="recommendation-badge left" id="recommended-side-badge">Left Side</span>
          </div>
          
          <p class="result-message" id="result-message">
            You should sit on the left side of the vehicle to minimize direct sunlight exposure.
          </p>

          <div class="exposure-breakdown">
            <div class="exposure-labels">
              <span class="lbl-left" id="exposure-lbl-left">Left: 0m</span>
              <span class="lbl-right" id="exposure-lbl-right">Right: 0m</span>
            </div>
            <div class="exposure-bar-container">
              <div class="bar-left" id="bar-left" style="width: 0%"></div>
              <div class="bar-right" id="bar-right" style="width: 0%"></div>
              <div class="bar-neutral" id="bar-neutral" style="width: 0%"></div>
            </div>
          </div>

          <div class="details-grid">
            <div class="detail-card">
              <label>Confidence</label>
              <div class="detail-val" id="confidence-val">High</div>
            </div>
            <div class="detail-card">
              <label>Cache Status</label>
              <div class="detail-val" id="cache-val">Miss</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Column: Interactive Map -->
    <div class="card map-card">
      <div id="map"></div>
    </div>
  </div>

  <script>
    let map;
    let directionsService;
    let directionsRenderer;
    let sourceAutocomplete;
    let destAutocomplete;
    let sourceAddressSelected = false;
    let destAddressSelected = false;

    // Google Maps Initialization Callback
    function initMap() {
      directionsService = new google.maps.DirectionsService();
      directionsRenderer = new google.maps.DirectionsRenderer({
        polylineOptions: {
          strokeColor: "#6366f1",
          strokeWeight: 6,
          strokeOpacity: 0.85
        },
        markerOptions: {
          animation: google.maps.Animation.DROP
        }
      });

      // Default view centered on India/Gujarat region
      const defaultCenter = { lat: 22.3072, lng: 72.8634 };
      map = new google.maps.Map(document.getElementById("map"), {
        zoom: 6,
        center: defaultCenter,
        disableDefaultUI: true,
        zoomControl: true,
        // Premium Dark Mode Styling
        styles: [
          { elementType: "geometry", stylers: [{ color: "#0f172a" }] },
          { elementType: "labels.text.stroke", stylers: [{ color: "#0f172a" }] },
          { elementType: "labels.text.fill", stylers: [{ color: "#64748b" }] },
          {
            featureType: "administrative.locality",
            elementType: "labels.text.fill",
            stylers: [{ color: "#cbd5e1" }]
          },
          {
            featureType: "poi",
            elementType: "labels.text.fill",
            stylers: [{ color: "#64748b" }]
          },
          {
            featureType: "poi.park",
            elementType: "geometry",
            stylers: [{ color: "#1e293b" }]
          },
          {
            featureType: "poi.park",
            elementType: "labels.text.fill",
            stylers: [{ color: "#475569" }]
          },
          {
            featureType: "road",
            elementType: "geometry",
            stylers: [{ color: "#1e293b" }]
          },
          {
            featureType: "road",
            elementType: "geometry.stroke",
            stylers: [{ color: "#334155" }]
          },
          {
            featureType: "road",
            elementType: "labels.text.fill",
            stylers: [{ color: "#94a3b8" }]
          },
          {
            featureType: "road.highway",
            elementType: "geometry",
            stylers: [{ color: "#334155" }]
          },
          {
            featureType: "road.highway",
            elementType: "geometry.stroke",
            stylers: [{ color: "#475569" }]
          },
          {
            featureType: "road.highway",
            elementType: "labels.text.fill",
            stylers: [{ color: "#cbd5e1" }]
          },
          {
            featureType: "water",
            elementType: "geometry",
            stylers: [{ color: "#020617" }]
          },
          {
            featureType: "water",
            elementType: "labels.text.fill",
            stylers: [{ color: "#475569" }]
          }
        ]
      });

      directionsRenderer.setMap(map);
      initAutocomplete();
    }

    function initAutocomplete() {
      const sourceInput = document.getElementById('source-input');
      const destInput = document.getElementById('dest-input');

      sourceAutocomplete = new google.maps.places.Autocomplete(sourceInput, {
        fields: ['geometry', 'formatted_address']
      });
      destAutocomplete = new google.maps.places.Autocomplete(destInput, {
        fields: ['geometry', 'formatted_address']
      });

      sourceAutocomplete.addListener('place_changed', () => {
        const place = sourceAutocomplete.getPlace();
        const coordsLbl = document.getElementById('source-coords-lbl');
        if (place.geometry && place.geometry.location) {
          const lat = place.geometry.location.lat().toFixed(4);
          const lng = place.geometry.location.lng().toFixed(4);
          document.getElementById('source-coords').value = `${lat},${lng}`;
          coordsLbl.textContent = `Coordinates: ${lat}, ${lng}`;
          coordsLbl.classList.add('visible');
          sourceAddressSelected = true;
          
          // Pan map to origin
          map.panTo(place.geometry.location);
          map.setZoom(13);
          
          // Render route instantly if both are selected
          updateMapRoute();
        } else {
          sourceAddressSelected = false;
          coordsLbl.classList.remove('visible');
        }
        validateFormState();
      });

      destAutocomplete.addListener('place_changed', () => {
        const place = destAutocomplete.getPlace();
        const coordsLbl = document.getElementById('dest-coords-lbl');
        if (place.geometry && place.geometry.location) {
          const lat = place.geometry.location.lat().toFixed(4);
          const lng = place.geometry.location.lng().toFixed(4);
          document.getElementById('dest-coords').value = `${lat},${lng}`;
          coordsLbl.textContent = `Coordinates: ${lat}, ${lng}`;
          coordsLbl.classList.add('visible');
          destAddressSelected = true;
          
          // Pan map to destination
          map.panTo(place.geometry.location);
          map.setZoom(13);
          
          // Render route instantly if both are selected
          updateMapRoute();
        } else {
          destAddressSelected = false;
          coordsLbl.classList.remove('visible');
        }
        validateFormState();
      });

      // Clear coords and route if user alters text manually
      sourceInput.addEventListener('input', () => {
        if (sourceInput.value === '') {
          sourceAddressSelected = false;
          document.getElementById('source-coords').value = '';
          document.getElementById('source-coords-lbl').classList.remove('visible');
          directionsRenderer.setDirections({ routes: [] }); // Clear map path
          validateFormState();
        }
      });

      destInput.addEventListener('input', () => {
        if (destInput.value === '') {
          destAddressSelected = false;
          document.getElementById('dest-coords').value = '';
          document.getElementById('dest-coords-lbl').classList.remove('visible');
          directionsRenderer.setDirections({ routes: [] }); // Clear map path
          validateFormState();
        }
      });
    }

    function updateMapRoute() {
      if (sourceAddressSelected && destAddressSelected) {
        const sourceAddress = document.getElementById('source-input').value;
        const destAddress = document.getElementById('dest-input').value;

        directionsService.route(
          {
            origin: sourceAddress,
            destination: destAddress,
            travelMode: google.maps.TravelMode.DRIVING
          },
          (result, status) => {
            if (status === 'OK') {
              directionsRenderer.setDirections(result);
            } else {
              console.error('Directions request failed due to ' + status);
            }
          }
        );
      }
    }

    function validateFormState() {
      const submitBtn = document.getElementById('submit-btn');
      submitBtn.disabled = !(sourceAddressSelected && destAddressSelected);
    }

    async function submitForm() {
      const source = document.getElementById('source-coords').value;
      const destination = document.getElementById('dest-coords').value;
      const departureVal = document.getElementById('departure-input').value;

      if (!source || !destination || !departureVal) return;

      const sourceAddress = document.getElementById('source-input').value;
      const destAddress = document.getElementById('dest-input').value;

      // Construct ISO timestamp with local timezone offset
      const localDate = new Date(departureVal);
      const offsetMinutes = -localDate.getTimezoneOffset();
      const offsetSign = offsetMinutes >= 0 ? '+' : '-';
      const offsetHours = String(Math.floor(Math.abs(offsetMinutes) / 60)).padStart(2, '0');
      const offsetMins = String(Math.abs(offsetMinutes) % 60).padStart(2, '0');
      const departure_time = `${departureVal}:00${offsetSign}${offsetHours}:${offsetMins}`;

      // Show spinner and disable button
      const submitBtn = document.getElementById('submit-btn');
      document.getElementById('btn-text').style.display = 'none';
      document.getElementById('btn-spinner').style.display = 'block';
      submitBtn.disabled = true;

      try {
        // Fetch recommendations from API
        const response = await fetch('/api/v1/recommendation', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ source, destination, departure_time })
        });

        const cacheHitHeader = response.headers.get('X-Cache') === 'HIT';
        const data = await response.json();

        if (response.ok) {
          renderResult(data, cacheHitHeader);
          
          // Trigger route rendering on map
          directionsService.route(
            {
              origin: sourceAddress,
              destination: destAddress,
              travelMode: google.maps.TravelMode.DRIVING
            },
            (result, status) => {
              if (status === 'OK') {
                directionsRenderer.setDirections(result);
              } else {
                console.error('Directions request failed due to ' + status);
              }
            }
          );
        } else {
          alert(`Error: ${data.error || 'Failed to analyze route'}`);
        }
      } catch (err) {
        alert(`Network Error: ${err.message}`);
      } finally {
        document.getElementById('btn-text').style.display = 'block';
        document.getElementById('btn-spinner').style.display = 'none';
        submitBtn.disabled = false;
      }
    }

    function renderResult(data, isCacheHit) {
      document.getElementById('placeholder-state').style.display = 'none';
      const content = document.getElementById('result-content');
      content.style.display = 'block';

      // Update badge
      const badge = document.getElementById('recommended-side-badge');
      badge.textContent = data.recommended_side === 'either' ? 'Either Side' : `${data.recommended_side} Side`;
      badge.className = 'recommendation-badge'; // reset
      badge.classList.add(data.recommended_side);

      // Update message
      document.getElementById('result-message').textContent = data.message;

      // Update exposure bar & labels
      const leftMin = data.left_exposure_minutes || 0;
      const rightMin = data.right_exposure_minutes || 0;
      
      document.getElementById('exposure-lbl-left').textContent = `Left: ${leftMin}m`;
      document.getElementById('exposure-lbl-right').textContent = `Right: ${rightMin}m`;

      const barLeft = document.getElementById('bar-left');
      const barRight = document.getElementById('bar-right');
      const barNeutral = document.getElementById('bar-neutral');

      if (data.recommended_side === 'either') {
        barLeft.style.width = '0%';
        barRight.style.width = '0%';
        barNeutral.style.width = '100%';
      } else {
        barNeutral.style.width = '0%';
        const total = leftMin + rightMin;
        if (total === 0) {
          barLeft.style.width = '50%';
          barRight.style.width = '50%';
        } else {
          barLeft.style.width = `${(leftMin / total) * 100}%`;
          barRight.style.width = `${(rightMin / total) * 100}%`;
        }
      }

      // Update confidence
      const confVal = document.getElementById('confidence-val');
      confVal.textContent = data.confidence;
      confVal.className = 'detail-val'; // reset
      confVal.classList.add(`conf-${data.confidence}`);

      // Update cache status
      document.getElementById('cache-val').textContent = isCacheHit ? 'Hit' : 'Miss';
    }

    // Set default departure time
    window.addEventListener('DOMContentLoaded', () => {
      const now = new Date();
      now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
      document.getElementById('departure-input').value = now.toISOString().slice(0, 16);
    });
  </script>
  <!-- Callback triggers initMap when script finishes loading -->
  <script src="https://maps.googleapis.com/maps/api/js?key=#{api_key}&libraries=places&callback=initMap" async defer></script>
</body>
</html>
    HTML
  end
end
