let map;
let directionsService;
let directionsRenderer;
let sourceAutocomplete;
let destAutocomplete;
let sourceAddressSelected = false;
let destAddressSelected = false;
let currentRouteIndex = 0;

// Visualization Global Variables
let routePolyline = null;
let activeMarkersMap = new Map();
let startMarker = null;
let endMarker = null;
let allStepsData = [];
let globalSampleRate = 1;

// Simulation & Timeline Global Variables
let currentStepsData = [];
let activeInfoWindow = null;
let simulationInterval = null;
let simCurrentIndex = 0;

const darkMapStyle = [
  { elementType: "geometry", stylers: [{ color: "#0f172a" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#0f172a" }, { weight: 2 }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#64748b" }] },
  {
    featureType: "administrative.locality",
    elementType: "labels.text.fill",
    stylers: [{ color: "#cbd5e1" }]
  },
  {
    featureType: "poi",
    elementType: "labels.text.fill",
    stylers: [{ color: "#94a3b8" }]
  },
  {
    featureType: "poi.park",
    elementType: "geometry",
    stylers: [{ color: "#1e293b" }]
  },
  {
    featureType: "poi.park",
    elementType: "labels.text.fill",
    stylers: [{ color: "#64748b" }]
  },
  {
    featureType: "road",
    elementType: "geometry",
    stylers: [{ color: "#1e293b" }]
  },
  {
    featureType: "road",
    elementType: "geometry.stroke",
    stylers: [{ color: "#0f172a" }]
  },
  {
    featureType: "road",
    elementType: "labels.text.fill",
    stylers: [{ color: "#475569" }]
  },
  {
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [{ color: "#334155" }]
  },
  {
    featureType: "road.highway",
    elementType: "geometry.stroke",
    stylers: [{ color: "#0f172a" }]
  },
  {
    featureType: "road.highway",
    elementType: "labels.text.fill",
    stylers: [{ color: "#cbd5e1" }]
  },
  {
    featureType: "transit",
    elementType: "geometry",
    stylers: [{ color: "#1e293b" }]
  },
  {
    featureType: "transit.station",
    elementType: "labels.text.fill",
    stylers: [{ color: "#94a3b8" }]
  },
  {
    featureType: "water",
    elementType: "geometry",
    stylers: [{ color: "#0b0f19" }]
  },
  {
    featureType: "water",
    elementType: "labels.text.fill",
    stylers: [{ color: "#475569" }]
  },
  {
    featureType: "water",
    elementType: "labels.text.stroke",
    stylers: [{ color: "#0f172a" }]
  }
];

// Google Maps Initialization Callback
function initMap() {
  directionsService = new google.maps.DirectionsService();
  directionsRenderer = new google.maps.DirectionsRenderer({
    suppressPolylines: true,
    suppressMarkers: true
  });

  // Default view centered on India/Gujarat region
  const defaultCenter = { lat: 22.3072, lng: 72.8634 };
  map = new google.maps.Map(document.getElementById("map"), {
    zoom: 6,
    center: defaultCenter,
    disableDefaultUI: true,
    zoomControl: true,
    mapId: 'DEMO_MAP_ID',
    styles: darkMapStyle
  });

  directionsRenderer.setMap(map);

  map.addListener('idle', () => {
    updateViewportMarkers();
  });

  // Listen for route index changes (e.g. clicking on alternative route lines on the map)
  directionsRenderer.addListener('routeindex_changed', () => {
    const idx = directionsRenderer.getRouteIndex();
    currentRouteIndex = idx;

    // Synchronize UI list highlights
    const items = document.querySelectorAll('.route-option-item');
    items.forEach((item, i) => {
      if (i === idx) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });

    // Redraw preview polyline for selected route
    const directions = directionsRenderer.getDirections();
    if (directions && directions.routes && directions.routes[idx]) {
      drawRoutePolyline(directions.routes[idx].overview_path);
    }
  });

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
      resetStateAndResults();
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
      resetStateAndResults();
      updateMapRoute();
    } else {
      destAddressSelected = false;
      coordsLbl.classList.remove('visible');
    }
    validateFormState();
  });

  // Clear coords and route if user alters text manually
  sourceInput.addEventListener('input', () => {
    resetStateAndResults();
    if (sourceInput.value === '') {
      sourceAddressSelected = false;
      document.getElementById('source-coords').value = '';
      document.getElementById('source-coords-lbl').classList.remove('visible');
      document.getElementById('route-options-group').style.display = 'none';
      directionsRenderer.setDirections({ routes: [] }); // Clear map markers
      validateFormState();
    }
  });

  destInput.addEventListener('input', () => {
    resetStateAndResults();
    if (destInput.value === '') {
      destAddressSelected = false;
      document.getElementById('dest-coords').value = '';
      document.getElementById('dest-coords-lbl').classList.remove('visible');
      document.getElementById('route-options-group').style.display = 'none';
      directionsRenderer.setDirections({ routes: [] }); // Clear map markers
      validateFormState();
    }
  });
}

function updateMapRoute() {
  if (sourceAddressSelected && destAddressSelected) {
    const source = document.getElementById('source-coords').value;
    const destination = document.getElementById('dest-coords').value;
    const departureVal = document.getElementById('departure-input').value;

    // Reset active index when source/destination updates
    currentRouteIndex = 0;

    const requestParams = {
      origin: source,
      destination: destination,
      travelMode: google.maps.TravelMode.DRIVING,
      provideRouteAlternatives: true
    };

    if (departureVal) {
      requestParams.drivingOptions = {
        departureTime: new Date(departureVal),
        trafficModel: google.maps.TrafficModel.BEST_ESTIMATE
      };
    }

    directionsService.route(
      requestParams,
      (result, status) => {
        if (status === 'OK') {
          // Ensure we show polylines during selection
          directionsRenderer.setOptions({ suppressPolylines: false, suppressMarkers: true });
          directionsRenderer.setDirections(result);
          directionsRenderer.setRouteIndex(0);

          // Draw custom start/end markers for the first route
          if (result.routes && result.routes[0]) {
            const leg = result.routes[0].legs[0];
            drawStartEndMarkers(leg.start_location, leg.end_location, leg.start_address, leg.end_address);
          }

          // Render alternative routes selection in UI
          const optionsGroup = document.getElementById('route-options-group');
          const optionsList = document.getElementById('route-options-list');

          if (result.routes && result.routes.length > 1) {
            optionsList.innerHTML = '';
            result.routes.forEach((route, idx) => {
              const leg = route.legs[0];
              const duration = leg.duration.text;
              const distance = leg.distance.text;
              const name = route.summary || `Route ${idx + 1}`;

              const item = document.createElement('div');
              item.className = `route-option-item${idx === 0 ? ' active' : ''}`;
              item.innerHTML = `
                <div class="route-option-info">
                  <span class="route-option-name">via ${name}</span>
                  <span class="route-option-meta">${distance}</span>
                </div>
                <span class="route-option-duration">${duration}</span>
              `;

              item.addEventListener('click', () => {
                currentRouteIndex = idx;
                directionsRenderer.setOptions({ suppressPolylines: false, suppressMarkers: true });
                directionsRenderer.setRouteIndex(idx);
                
                // Highlight selected item
                document.querySelectorAll('.route-option-item').forEach((el, i) => {
                  el.classList.toggle('active', i === idx);
                });

                // Redraw preview polyline
                drawRoutePolyline(route.overview_path);

                // Redraw custom start/end markers
                const selectedLeg = route.legs[0];
                drawStartEndMarkers(selectedLeg.start_location, selectedLeg.end_location, selectedLeg.start_address, selectedLeg.end_address);
              });

              optionsList.appendChild(item);
            });
            optionsGroup.style.display = 'block';
          } else {
            optionsGroup.style.display = 'none';
          }

          // Draw initial preview polyline from browser directions path
          if (result.routes && result.routes[0]) {
            drawRoutePolyline(result.routes[0].overview_path);
          }
        } else {
          console.error('[ShadowMe] Directions request failed due to: ' + status);
        }
      }
    );
  }
}

function swapLocations() {
  const sourceInput = document.getElementById('source-input');
  const destInput = document.getElementById('dest-input');
  const sourceCoords = document.getElementById('source-coords');
  const destCoords = document.getElementById('dest-coords');
  const sourceLbl = document.getElementById('source-coords-lbl');
  const destLbl = document.getElementById('dest-coords-lbl');

  // Swap text inputs
  const tempAddress = sourceInput.value;
  sourceInput.value = destInput.value;
  destInput.value = tempAddress;

  // Swap hidden coordinates
  const tempCoords = sourceCoords.value;
  sourceCoords.value = destCoords.value;
  destCoords.value = tempCoords;

  // Swap address selected state flags
  const tempSelected = sourceAddressSelected;
  sourceAddressSelected = destAddressSelected;
  destAddressSelected = tempSelected;

  // Swap coordinates labels visibility & text
  const tempLblText = sourceLbl.textContent;
  sourceLbl.textContent = destLbl.textContent;
  destLbl.textContent = tempLblText;

  const sourceHasClass = sourceLbl.classList.contains('visible');
  const destHasClass = destLbl.classList.contains('visible');
  sourceLbl.classList.toggle('visible', destHasClass);
  destLbl.classList.toggle('visible', sourceHasClass);

  // Reset state, validate form, and update map route
  resetStateAndResults();
  validateFormState();
  updateMapRoute();
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

  // Construct ISO timestamp with local timezone offset
  const localDate = new Date(departureVal);
  const offsetMinutes = -localDate.getTimezoneOffset();
  const offsetSign = offsetMinutes >= 0 ? '+' : '-';
  const offsetHours = String(Math.floor(Math.abs(offsetMinutes) / 60)).padStart(2, '0');
  const offsetMins = String(Math.abs(offsetMinutes) % 60).padStart(2, '0');
  
  const dateParts = departureVal.split(' ');
  const dateStr = dateParts[0];
  const timeStr = dateParts[1];
  const departure_time = `${dateStr}T${timeStr}:00${offsetSign}${offsetHours}:${offsetMins}`;

  // Show spinner, disable button, and clear pulse highlight
  const submitBtn = document.getElementById('submit-btn');
  submitBtn.classList.remove('pulse-highlight');
  document.getElementById('btn-text').style.display = 'none';
  document.getElementById('btn-spinner').style.display = 'block';
  submitBtn.disabled = true;

  // Toggle loading skeleton and hide result/placeholder
  document.getElementById('placeholder-state').style.display = 'none';
  document.getElementById('result-content').style.display = 'none';
  document.getElementById('loading-state').style.display = 'block';

  try {
    const includeStepsCheckbox = document.getElementById('include-steps-checkbox');
    const includeSteps = includeStepsCheckbox ? includeStepsCheckbox.checked : false;

    // Fetch recommendations from API
    const response = await fetch('/api/v1/recommendation', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ source, destination, departure_time, route_index: currentRouteIndex, include_steps: includeSteps })
    });

    const cacheHitHeader = response.headers.get('X-Cache') === 'HIT';
    const data = await response.json();

    // Hide loading state
    document.getElementById('loading-state').style.display = 'none';

    if (response.ok) {
      renderResult(data, cacheHitHeader);
      directionsRenderer.setOptions({ suppressPolylines: true, suppressMarkers: true });
      
      // Scroll to result panel on mobile/tablet
      if (window.innerWidth <= 1024) {
        document.getElementById('result-panel').scrollIntoView({ behavior: 'smooth' });
      }
    } else {
      document.getElementById('placeholder-state').style.display = 'block';
      showToast(`Error: ${data.error || 'Failed to analyze route'}`, 'error');
    }
  } catch (err) {
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('placeholder-state').style.display = 'block';
    showToast(`Network Error: ${err.message}`, 'error');
  } finally {
    document.getElementById('btn-text').style.display = 'block';
    document.getElementById('btn-spinner').style.display = 'none';
    submitBtn.disabled = false;
  }
}

function formatDuration(minutes) {
  if (minutes <= 0) return '0m';
  
  const days = Math.floor(minutes / 1440);
  const hours = Math.floor((minutes % 1440) / 60);
  const mins = minutes % 60;
  
  let parts = [];
  if (days > 0) {
    parts.push(`${days}d`);
    if (hours > 0 || mins > 0) {
      parts.push(`${hours}h`);
    }
    if (mins > 0) {
      parts.push(`${mins}m`);
    }
  } else if (hours > 0) {
    parts.push(`${hours}h`);
    if (mins > 0) {
      parts.push(`${mins}m`);
    }
  } else {
    parts.push(`${mins}m`);
  }
  return parts.join(' ');
}

function renderResult(data, isCacheHit) {
  document.getElementById('placeholder-state').style.display = 'none';
  document.getElementById('loading-state').style.display = 'none';
  const content = document.getElementById('result-content');
  content.style.display = 'block';

  // Clear previous visualization elements
  clearVisualization();

  // Save steps globally for simulation & timeline interaction
  const allSteps = data.steps || [];
  allSteps.forEach((step, idx) => {
    step.absoluteIndex = idx;
  });
  allStepsData = allSteps;

  // Calculate global sample rate for timeline (aim to show ~150 items in the list)
  const timelineCap = 150;
  globalSampleRate = 1;
  if (allSteps.length > timelineCap) {
    globalSampleRate = Math.ceil(allSteps.length / timelineCap);
  }

  let visualSteps = [...allSteps];
  if (visualSteps.length > timelineCap) {
    visualSteps = visualSteps.filter((_, idx) => idx % globalSampleRate === 0);
  }
  currentStepsData = visualSteps;

  // Draw exact backend route polyline and checkpoints
  const steps = visualSteps;
  if (allSteps.length > 0) {
    // 1. Draw exact backend route polyline
    const backendPath = [];
    allSteps.forEach(step => {
      const sLat = parseFloat(step.start_lat);
      const sLng = parseFloat(step.start_lng);
      const eLat = parseFloat(step.end_lat);
      const eLng = parseFloat(step.end_lng);
      if (!isNaN(sLat) && !isNaN(sLng)) {
        backendPath.push(new google.maps.LatLng(sLat, sLng));
      }
      if (!isNaN(eLat) && !isNaN(eLng)) {
        backendPath.push(new google.maps.LatLng(eLat, eLng));
      }
    });
    drawRoutePolyline(backendPath);

    // Draw custom start and end markers (S & D pins) so they remain visible
    const firstStep = allSteps[0];
    const lastStep = allSteps[allSteps.length - 1];
    const startLatLng = new google.maps.LatLng(parseFloat(firstStep.start_lat), parseFloat(firstStep.start_lng));
    const endLatLng = new google.maps.LatLng(parseFloat(lastStep.end_lat), parseFloat(lastStep.end_lng));
    const startAddr = document.getElementById('source-input').value;
    const endAddr = document.getElementById('dest-input').value;
    drawStartEndMarkers(startLatLng, endLatLng, startAddr, endAddr);

    // Populate timeline list
    const timelineList = document.getElementById('timeline-list');
    timelineList.innerHTML = '';

    const fragment = document.createDocumentFragment();

    steps.forEach((step, index) => {
      const item = document.createElement('div');
      item.className = 'timeline-item';
      item.id = `timeline-item-${index}`;

      const timeStr = new Date(step.midpoint_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      const distanceKm = (step.distance / 1000.0).toFixed(1);
      const durationMins = Math.round(step.duration / 60.0) || 1;
      const bearingDeg = Math.round(step.bearing);

      // Find direction symbol/name
      let dirStr = '';
      if (bearingDeg >= 337.5 || bearingDeg < 22.5) dirStr = 'N';
      else if (bearingDeg >= 22.5 && bearingDeg < 67.5) dirStr = 'NE';
      else if (bearingDeg >= 67.5 && bearingDeg < 112.5) dirStr = 'E';
      else if (bearingDeg >= 112.5 && bearingDeg < 157.5) dirStr = 'SE';
      else if (bearingDeg >= 157.5 && bearingDeg < 202.5) dirStr = 'S';
      else if (bearingDeg >= 202.5 && bearingDeg < 247.5) dirStr = 'SW';
      else if (bearingDeg >= 247.5 && bearingDeg < 292.5) dirStr = 'W';
      else dirStr = 'NW';

      const isNight = parseFloat(step.sun_elevation) <= 0.0;
      const side = isNight ? 'night' : step.sun_side;

      const absIdx = (step.absoluteIndex !== undefined) ? step.absoluteIndex : index;
      item.innerHTML = `
        <div class="timeline-item-left">
          <span class="timeline-item-title">Checkpoint ${absIdx + 1} &bull; ${timeStr}</span>
          <span class="timeline-item-meta">${distanceKm} km &bull; ${durationMins}m &bull; Heading ${bearingDeg}° (${dirStr})</span>
        </div>
        <div class="timeline-item-right">
          <span class="timeline-badge ${side}">${side}</span>
        </div>
      `;

      item.addEventListener('click', () => {
        selectCheckpoint(index, true);
      });

      item.addEventListener('mouseenter', () => {
        const originalIdx = absIdx;
        const val = activeMarkersMap.get(originalIdx);
        if (val && val.marker) {
          const marker = val.marker;
          if (marker.content) {
            marker.content.classList.add('hovered');
            marker.zIndex = 1001;
            if (simCurrentIndex !== index) {
              if (activeInfoWindow) activeInfoWindow.close();
              const step = allStepsData[originalIdx];
              const markerColor = marker.content.style.backgroundColor;
              openInfoWindowForMarker(marker, originalIdx, step, markerColor);
            }
          }
        }
      });

      item.addEventListener('mouseleave', () => {
        const originalIdx = absIdx;
        const val = activeMarkersMap.get(originalIdx);
        if (val && val.marker) {
          const marker = val.marker;
          if (marker.content) {
            marker.content.classList.remove('hovered');
            marker.zIndex = originalIdx;
            if (simCurrentIndex !== index) {
              if (marker.infoWindow) {
                marker.infoWindow.close();
              }
              if (activeInfoWindow === marker.infoWindow) activeInfoWindow = null;
              
              // Restore info window of currently selected checkpoint, if any
              const activeStep = currentStepsData[simCurrentIndex];
              const activeOriginalIdx = (activeStep && activeStep.absoluteIndex !== undefined) ? activeStep.absoluteIndex : simCurrentIndex;
              const activeVal = activeMarkersMap.get(activeOriginalIdx);
              if (activeVal && activeVal.marker) {
                const activeMarker = activeVal.marker;
                const activeStepObj = allStepsData[activeOriginalIdx];
                const activeColor = activeMarker.content.style.backgroundColor;
                openInfoWindowForMarker(activeMarker, activeOriginalIdx, activeStepObj, activeColor);
              }
            }
          }
        }
      });

      fragment.appendChild(item);
    });

    timelineList.appendChild(fragment);

    document.getElementById('timeline-container').style.display = 'block';

    // Dynamically compute and show markers for current viewport bounds and zoom level
    updateViewportMarkers();

    // Select the initial checkpoint (index 0) by default after the browser paint loop finishes
    setTimeout(() => {
      selectCheckpoint(0, false);
    }, 50);
  }

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
  const nightMin = data.night_exposure_minutes || 0;
  const frontBehindMin = data.front_behind_exposure_minutes || 0;
  
  document.getElementById('exposure-lbl-left').textContent = `Left: ${formatDuration(leftMin)}`;
  document.getElementById('exposure-lbl-front-behind').textContent = `Front/Behind: ${formatDuration(frontBehindMin)}`;
  document.getElementById('exposure-lbl-right').textContent = `Right: ${formatDuration(rightMin)}`;
  document.getElementById('exposure-lbl-neutral').textContent = `Night: ${formatDuration(nightMin)}`;

  const barLeft = document.getElementById('bar-left');
  const barRight = document.getElementById('bar-right');
  const barNeutral = document.getElementById('bar-neutral');
  const barFrontBehind = document.getElementById('bar-front-behind');

  const total = leftMin + rightMin + nightMin + frontBehindMin;
  if (total === 0) {
    barLeft.style.width = '0%';
    barRight.style.width = '0%';
    barFrontBehind.style.width = '0%';
    barNeutral.style.width = '100%';
  } else {
    barLeft.style.width = `${(leftMin / total) * 100}%`;
    barFrontBehind.style.width = `${(frontBehindMin / total) * 100}%`;
    barRight.style.width = `${(rightMin / total) * 100}%`;
    barNeutral.style.width = `${(nightMin / total) * 100}%`;
  }

  // Update confidence
  const confVal = document.getElementById('confidence-val');
  confVal.textContent = data.confidence;
  confVal.className = 'detail-val'; // reset
  confVal.classList.add(`conf-${data.confidence}`);

  // Update cache status
  document.getElementById('cache-val').textContent = isCacheHit ? 'Hit' : 'Miss';

  // Initialize icons
  if (window.lucide) {
    lucide.createIcons();
  }
}

// Visualization Helpers
function drawRoutePolyline(pathPoints) {
  if (routePolyline) {
    routePolyline.setMap(null);
  }
  routePolyline = new google.maps.Polyline({
    path: pathPoints,
    geodesic: true,
    strokeColor: "#6366f1",
    strokeWeight: 6,
    strokeOpacity: 0.85,
    map: map
  });
}

function clearVisualization() {
  simCurrentIndex = 0;
  if (routePolyline) {
    routePolyline.setMap(null);
    routePolyline = null;
  }
  if (startMarker) {
    startMarker.setMap(null);
    startMarker = null;
  }
  if (endMarker) {
    endMarker.setMap(null);
    endMarker = null;
  }

  // Clear all active viewport markers and sun rays
  activeMarkersMap.forEach(val => {
    if (val.marker) val.marker.setMap(null);
    if (val.sunRay) val.sunRay.setMap(null);
  });
  activeMarkersMap.clear();
  allStepsData = [];

  stopSimulation();
  document.getElementById('timeline-container').style.display = 'none';
}

function resetStateAndResults() {
  clearVisualization();
  document.getElementById('placeholder-state').style.display = 'block';
  document.getElementById('result-content').style.display = 'none';
  document.getElementById('loading-state').style.display = 'none';
  
  // Hide and clear route options
  document.getElementById('route-options-group').style.display = 'none';
  document.getElementById('route-options-list').innerHTML = '';
  
  const submitBtn = document.getElementById('submit-btn');
  if (submitBtn) {
    submitBtn.classList.add('pulse-highlight');
  }

  // Reset map view to default center and zoom
  if (map) {
    map.setZoom(6);
    map.setCenter({ lat: 22.3072, lng: 72.8634 });
  }
}

function updateViewportMarkers() {
  if (!map || allStepsData.length === 0) return;
  const bounds = map.getBounds();
  if (!bounds) return;

  const zoom = map.getZoom();
  
  // Determine the sampling step based on map zoom level
  let step = 1;
  if (zoom < 7) {
    step = 16;
  } else if (zoom < 9) {
    step = 8;
  } else if (zoom < 11) {
    step = 4;
  } else if (zoom < 13) {
    step = 2;
  }

  // Filter steps that are within the current map viewport bounds
  const margin = 0.05; // small buffer outside bounds
  const northEast = bounds.getNorthEast();
  const southWest = bounds.getSouthWest();
  const minLat = southWest.lat() - margin;
  const maxLat = northEast.lat() + margin;
  const minLng = southWest.lng() - margin;
  const maxLng = northEast.lng() + margin;

  const visibleCandidates = [];
  for (let i = 0; i < allStepsData.length; i++) {
    const s = allStepsData[i];
    const lat = parseFloat(s.midpoint_lat);
    const lng = parseFloat(s.midpoint_lng);
    if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
      // Keep only steps matching the zoom step selection
      if (i % step === 0) {
        visibleCandidates.push({ step: s, originalIndex: i });
      }
    }
  }

  // Keep a max cap on active markers to prevent browser overload
  const maxMarkers = 150;
  let targetVisible = visibleCandidates;
  if (visibleCandidates.length > maxMarkers) {
    const subSample = Math.ceil(visibleCandidates.length / maxMarkers);
    targetVisible = visibleCandidates.filter((_, idx) => idx % subSample === 0);
  }

  const targetIndices = new Set(targetVisible.map(item => item.originalIndex));

  // 1. Remove markers that are no longer needed
  for (const [idx, val] of activeMarkersMap.entries()) {
    if (!targetIndices.has(idx)) {
      if (val.marker) val.marker.setMap(null);
      if (val.sunRay) val.sunRay.setMap(null);
      activeMarkersMap.delete(idx);
    }
  }

  // 2. Add new markers
  targetVisible.forEach(item => {
    const idx = item.originalIndex;
    if (activeMarkersMap.has(idx)) {
      // If the marker is already active, make sure it is attached to the map
      const activeItem = activeMarkersMap.get(idx);
      if (activeItem.marker.map !== map) {
        activeItem.marker.setMap(map);
      }
      if (activeItem.sunRay && activeItem.sunRay.map !== map) {
        activeItem.sunRay.setMap(map);
      }
      return;
    }

    const step = item.step;
    const midLat = parseFloat(step.midpoint_lat);
    const midLng = parseFloat(step.midpoint_lng);
    if (isNaN(midLat) || isNaN(midLng)) return;

    const midpointPos = new google.maps.LatLng(midLat, midLng);

    // Color midpoint marker: Left = Blue, Right = Pink, Front/Behind = Yellow, Night = Gray
    let markerColor = "#9ca3af";
    const sunElev = parseFloat(step.sun_elevation);
    if (!isNaN(sunElev) && sunElev > 0) {
      if (step.sun_side === 'left') {
        markerColor = "#3b82f6";
      } else if (step.sun_side === 'right') {
        markerColor = "#ec4899";
      } else if (step.sun_side === 'front' || step.sun_side === 'behind') {
        markerColor = "#eab308";
      }
    }

    const markerContent = document.createElement('div');
    markerContent.className = 'checkpoint-marker';
    markerContent.style.backgroundColor = markerColor;

    // If this marker matches the currently selected simulation/timeline index, highlight it
    const activeStep = currentStepsData[simCurrentIndex];
    const activeAbsIdx = (activeStep && activeStep.absoluteIndex !== undefined) ? activeStep.absoluteIndex : simCurrentIndex;
    if (idx === activeAbsIdx) {
      markerContent.classList.add('active');
      setTimeout(() => {
        openInfoWindowForMarker(marker, idx, step, markerColor);
      }, 50);
    }

    const marker = new google.maps.marker.AdvancedMarkerElement({
      position: midpointPos,
      map: map,
      title: `Checkpoint ${idx + 1}`,
      content: markerContent
    });

    // Draw sun direction vector if sun is above the horizon
    let sunRay = null;
    const sunAz = parseFloat(step.sun_azimuth);
    if (!isNaN(sunElev) && sunElev > 0 && !isNaN(sunAz)) {
      const offsetScale = 0.0015; // Ray length
      const rad = sunAz * Math.PI / 180;
      const endLat = midLat + offsetScale * Math.cos(rad);
      const endLng = midLng + offsetScale * Math.sin(rad);
      if (!isNaN(endLat) && !isNaN(endLng)) {
        const sunEndPos = new google.maps.LatLng(endLat, endLng);

        sunRay = new google.maps.Polyline({
          path: [midpointPos, sunEndPos],
          geodesic: true,
          strokeColor: "#eab308",
          strokeOpacity: 0.8,
          strokeWeight: 2.5,
          map: map,
          icons: [{
            icon: {
              path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
              scale: 2,
              fillColor: "#eab308",
              fillOpacity: 1,
              strokeColor: "#eab308",
              strokeWeight: 1
            },
            offset: '100%'
          }]
        });
      }
    }

    // Trigger selection on marker click
    marker.addListener('click', () => {
      const closestVisualIdx = Math.round(idx / globalSampleRate);
      selectCheckpoint(closestVisualIdx, false);
      openInfoWindowForMarker(marker, idx, step, markerColor);
    });

    activeMarkersMap.set(idx, { marker, sunRay });
  });
}

function openInfoWindowForMarker(marker, idx, step, markerColor) {
  if (activeInfoWindow) activeInfoWindow.close();

  const displayColor = markerColor === "rgb(234, 179, 8)" ? "#b45309" : markerColor;
  const isNight = parseFloat(step.sun_elevation) <= 0.0;
  const displaySide = isNight ? 'night' : step.sun_side;

  const contentString = `
    <div style="color: #0f172a; font-family: sans-serif; font-size: 12px; padding: 4px; line-height: 1.4; min-width: 160px;">
      <strong style="display: block; margin-bottom: 4px; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px;">Checkpoint ${idx + 1}</strong>
      <b>Time:</b> ${new Date(step.midpoint_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}<br/>
      <b>Bearing (Heading):</b> ${Math.round(step.bearing)}°<br/>
      <b>Sun Azimuth:</b> ${Math.round(step.sun_azimuth)}°<br/>
      <b>Sun Elevation:</b> ${Math.round(step.sun_elevation)}°<br/>
      <b>Sun Side Exposure:</b> <span style="font-weight: bold; text-transform: uppercase; color: ${displayColor};">${displaySide}</span>
    </div>
  `;

  if (!marker.infoWindow) {
    marker.infoWindow = new google.maps.InfoWindow({
      content: contentString
    });
  } else {
    marker.infoWindow.setContent(contentString);
  }

  marker.infoWindow.open(map, marker);
  activeInfoWindow = marker.infoWindow;
}

// Draw custom glowing Start and End markers on the map
function drawStartEndMarkers(startPos, endPos, startAddr, endAddr) {
  if (startMarker) startMarker.setMap(null);
  if (endMarker) endMarker.setMap(null);

  // Custom green start marker content (S = Source)
  const startContent = document.createElement('div');
  startContent.style.width = '24px';
  startContent.style.height = '24px';
  startContent.style.borderRadius = '50%';
  startContent.style.backgroundColor = '#10b981';
  startContent.style.border = '2px solid #ffffff';
  startContent.style.boxShadow = '0 0 10px rgba(16, 185, 129, 0.6)';
  startContent.style.display = 'flex';
  startContent.style.alignItems = 'center';
  startContent.style.justifyContent = 'center';
  startContent.style.color = '#ffffff';
  startContent.style.fontSize = '12px';
  startContent.style.fontWeight = '800';
  startContent.style.fontFamily = "'Inter', sans-serif";
  startContent.innerText = 'S';

  startMarker = new google.maps.marker.AdvancedMarkerElement({
    position: startPos,
    map: map,
    title: `Start: ${startAddr || 'Origin'}`,
    content: startContent,
    zIndex: 1000
  });

  // Custom pink/red end marker content (D = Destination)
  const endContent = document.createElement('div');
  endContent.style.width = '24px';
  endContent.style.height = '24px';
  endContent.style.borderRadius = '50%';
  endContent.style.backgroundColor = '#ec4899';
  endContent.style.border = '2px solid #ffffff';
  endContent.style.boxShadow = '0 0 10px rgba(236, 72, 153, 0.6)';
  endContent.style.display = 'flex';
  endContent.style.alignItems = 'center';
  endContent.style.justifyContent = 'center';
  endContent.style.color = '#ffffff';
  endContent.style.fontSize = '12px';
  endContent.style.fontWeight = '800';
  endContent.style.fontFamily = "'Inter', sans-serif";
  endContent.innerText = 'D';

  endMarker = new google.maps.marker.AdvancedMarkerElement({
    position: endPos,
    map: map,
    title: `Destination: ${endAddr || 'Destination'}`,
    content: endContent,
    zIndex: 1000
  });
}

// Sliding custom Toast notification system
function showToast(message, type = 'info') {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  
  let iconName = 'info';
  if (type === 'success') iconName = 'check-circle';
  if (type === 'error') iconName = 'alert-triangle';
  
  toast.innerHTML = `
    <div class="toast-icon"><i data-lucide="${iconName}" style="width: 18px; height: 18px;"></i></div>
    <div class="toast-message">${message}</div>
    <button class="toast-close" onclick="this.parentElement.remove(); checkToastContainerEmpty();"><i data-lucide="x" style="width: 14px; height: 14px;"></i></button>
  `;
  
  container.appendChild(toast);
  
  if (window.lucide) {
    lucide.createIcons();
  }
  
  // Trigger slide-in
  container.classList.add('active');
  
  // Auto dismiss
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'scale(0.9)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => {
      toast.remove();
      checkToastContainerEmpty();
    }, 300);
  }, 4000);
}

function checkToastContainerEmpty() {
  const container = document.getElementById('toast-container');
  if (container && container.children.length === 0) {
    container.classList.remove('active');
  }
}

// Checkpoint interaction logic
function selectCheckpoint(index, pan = true) {
  simCurrentIndex = index;
  document.querySelectorAll('.timeline-item').forEach(el => el.classList.remove('active'));
  
  const container = document.getElementById('timeline-list');
  const item = document.getElementById(`timeline-item-${index}`);
  if (container && item) {
    item.classList.add('active');
    
    // Only scroll the container internally to keep viewport scroll intact
    const containerTop = container.scrollTop;
    const containerBottom = containerTop + container.clientHeight;
    const elemTop = item.offsetTop - container.offsetTop;
    const elemBottom = elemTop + item.offsetHeight;
    
    if (elemTop < containerTop) {
      container.scrollTo({ top: elemTop, behavior: 'smooth' });
    } else if (elemBottom > containerBottom) {
      container.scrollTo({ top: elemBottom - container.clientHeight, behavior: 'smooth' });
    }
  }
  
  // Update active checkpoint styles on the map
  activeMarkersMap.forEach((val, idx) => {
    if (val.marker && val.marker.content) {
      val.marker.content.classList.remove('active');
      val.marker.zIndex = idx; // reset zIndex
    }
  });
  
  // Calculate the original index corresponding to this visual step index
  const activeStep = currentStepsData[index];
  const originalIdx = (activeStep && activeStep.absoluteIndex !== undefined) ? activeStep.absoluteIndex : index;
  const activeItem = activeMarkersMap.get(originalIdx);
  if (activeItem && activeItem.marker) {
    const marker = activeItem.marker;
    if (marker.content) {
      marker.content.classList.add('active');
      marker.zIndex = 950;
    }
    
    const step = allStepsData[originalIdx];
    const markerColor = marker.content.style.backgroundColor;
    openInfoWindowForMarker(marker, originalIdx, step, markerColor);
    
    if (pan) {
      map.panTo(marker.position);
      if (map.getZoom() < 10) {
        map.setZoom(11);
      }
    }
  } else {
    // If the marker is not currently created (e.g. out of viewport),
    // we can still pan to it, and map 'idle' listener will automatically create it!
    const step = allStepsData[originalIdx];
    if (step && pan) {
      const lat = parseFloat(step.midpoint_lat);
      const lng = parseFloat(step.midpoint_lng);
      if (!isNaN(lat) && !isNaN(lng)) {
        const pos = new google.maps.LatLng(lat, lng);
        map.panTo(pos);
        if (map.getZoom() < 10) {
          map.setZoom(11);
        }
      }
    }
  }
}

// Play simulation controls
function toggleSimulation() {
  if (simulationInterval) {
    stopSimulation();
  } else {
    startSimulation();
  }
}

function startSimulation() {
  if (!currentStepsData || currentStepsData.length === 0) return;
  
  const playBtn = document.getElementById('play-sim-btn');
  playBtn.classList.add('active');
  playBtn.innerHTML = `<i data-lucide="pause" style="width: 14px; height: 14px;"></i>`;
  playBtn.title = "Pause Simulation";
  
  if (window.lucide) {
    lucide.createIcons();
  }
  
  if (simCurrentIndex === undefined || simCurrentIndex === null || simCurrentIndex < 0 || simCurrentIndex >= currentStepsData.length - 1) {
    simCurrentIndex = 0;
  }
  selectCheckpoint(simCurrentIndex, true);
  
  const speedSelect = document.getElementById('sim-speed-select');
  const speedMultiplier = parseFloat(speedSelect ? speedSelect.value : 1.0);
  const intervalMs = Math.round(2000 / speedMultiplier);
  
  simulationInterval = setInterval(() => {
    simCurrentIndex++;
    if (simCurrentIndex >= currentStepsData.length) {
      stopSimulation();
      showToast("Simulation completed!", "success");
    } else {
      selectCheckpoint(simCurrentIndex, true);
    }
  }, intervalMs);
}

function updateSimulationSpeed() {
  const select = document.getElementById('sim-speed-select');
  if (select) {
    const val = parseFloat(select.value);
    
    if (simulationInterval) {
      clearInterval(simulationInterval);
      const intervalMs = Math.round(2000 / val);
      
      simulationInterval = setInterval(() => {
        simCurrentIndex++;
        if (simCurrentIndex >= currentStepsData.length) {
          stopSimulation();
          showToast("Simulation completed!", "success");
        } else {
          selectCheckpoint(simCurrentIndex, true);
        }
      }, intervalMs);
    }
  }
}

function stopSimulation() {
  if (!simulationInterval) return;

  clearInterval(simulationInterval);
  simulationInterval = null;
  
  const playBtn = document.getElementById('play-sim-btn');
  if (playBtn) {
    playBtn.classList.remove('active');
    playBtn.innerHTML = `<i data-lucide="play" style="width: 14px; height: 14px;"></i>`;
    playBtn.title = "Play Simulation";
    if (window.lucide) {
      lucide.createIcons();
    }
  }
}

// Set default departure time with Flatpickr & initialize Lucide icons
window.addEventListener('DOMContentLoaded', () => {
  flatpickr("#departure-input", {
    enableTime: true,
    time_24hr: true,
    dateFormat: "Y-m-d H:i",
    defaultDate: new Date(),
    disableMobile: "true", // Force flatpickr calendar view on all devices
    onChange: () => {
      resetStateAndResults();
      updateMapRoute();
    }
  });
  
  if (window.lucide) {
    lucide.createIcons();
  }
});
