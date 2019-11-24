$(document).ready(function() {
  //Create the main map tiles for leaflet
  var layer = L.tileLayer('https://api.mapbox.com/v4/mapbox.emerald/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiZGV2dHJhY2tlciIsImEiOiJjaWhzdnplbzUwMDJ3dzRrcGVyN2licGFpIn0.a3sZ1t6v-N1nxFCDIiGblQ', {
            attribution: '&copy; <a href="https://www.mapbox.com/map-feedback/">Mapbox</a> &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        });
  // Set the zoom level based on the area of the country that's being mapped
  if (countryBounds[window.countryCode][2] != null){
    zoomFactor = countryBounds[window.countryCode][2];
  }
  else{
    zoomFactor = 6;
  }
  // Create the main leaflet map
  map = new L.Map('countryMap', {
      center: new L.LatLng(countryBounds[window.countryCode][0], countryBounds[window.countryCode][1]), 
      zoom: zoomFactor,  
      layers: [layer]
  });
  //Create the map borderline for the target country
  var mapBorder = {
      "type": "Feature",
      "properties": {
          "popupContent": window.countryName,
          "style": {
            stroke: true,
            weight: 1,
            color: "red",
            opacity: 1,
            fillColor: "#204B63",
            fillOpacity: 0.2
          }
      },
      "geometry": {
          "type": window.geometryType,
          "coordinates": window.coordinates
      }
  };
  // Load the map marker data from the API response
  var mapMarkers = window.mainMarkers;
  // Define how the popup will react when clicked upon.
  function onEachFeature(feature, layer) {
    var popupContent = "";

    if (feature.properties && feature.properties.popupContent) {
      popupContent += feature.properties.popupContent;
    }

    layer.bindPopup(popupContent);
  }
  // Draw the map border based on previously created mapborder and add it to the main leaflet map from line 15
  L.geoJSON([mapBorder], {
    style: function (feature) {
      return feature.properties && feature.properties.style;
    },

    onEachFeature: onEachFeature,

    pointToLayer: function (feature, latlng) {
      return L.circleMarker(latlng, {
        radius: 6,
        fillColor: "red",
        color: "black",
        weight: 1,
        opacity: 1,
        fillOpacity: 0.3
      });
    }
  }).addTo(map);

  //Draw each of the markers based on the API data and add them to the main leaflet map
  var markers = L.markerClusterGroup({ chunkedLoading: true });
  $.each(mapMarkers,function(index, marker){
    var dtUrl = "/projects/" + marker['iati_identifier'];
    var title = marker['title'];
    var prepAltText = 'Project title: ' + title + '. Project identifier: ' + marker['iati_identifier'] + '. Project location on map: ' + marker['loc'];
    var tempMarker = L.marker(L.latLng(marker.geometry.coordinates[1],marker.geometry.coordinates[0]),{
      title: title,
      keyboard: true,
      alt: prepAltText
    });
    tempMarker.bindPopup("<a href='" + dtUrl + "'>" + title + " (" + marker['iati_identifier'] + ")</a>" + "<br />" + marker['loc']);
    markers.addLayer(tempMarker); 
  });
  map.addLayer(markers);
});