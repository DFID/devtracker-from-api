$(document).ready(function () {
  function calculateOpacity(countryBudget, maxBudget) {
    return (countryBudget / maxBudget) + 0.3
  }

  function calculateBrightness(countryBudget, max) {
    return d3.rgb("#79A9D6").brighter(-(countryBudget / max) * 3).toString()
  }

  function getPopupHTML(countryData) {
    var date = new Date();
    var currentFY = "";
    if (date.getMonth() < 3)
      currentFY = "FY" + (date.getFullYear() - 1) + "/" + date.getFullYear();
    else
      currentFY = "FY" + date.getFullYear() + "/" + (date.getFullYear() + 1);
    return "" +
      "<div class='popup' style='width: auto;'>" +
      "   <h3 class='govuk-heading-s'>" + countryData.country + "</h3>" +
      "   <div class='app-country-map-data'>" +
      "       <div class='app-country-map-data--title'>Country budget " + currentFY + "</div>" +
      "       <div class='app-country-map-data--stat'>\u00A3" + addCommas(countryData.budget) + "</div>" +
      "   </div>" +
      "   <div><a href='/countries/" + countryData.id + "' class='govuk-link govuk-!-font-size-14'>View country information</a></div>" +
      "   <div class='app-country-map-data govuk-!-margin-top-3'>" +
      "       <div class='app-country-map-data--title'>Number of Active Project(s)</div>" +
      "       <div class='app-country-map-data--stat'>" + countryData.projects + "</div>" +
      "   </div>" +
      "   <div><a href='/countries/" + countryData.id + "/projects' class='govuk-link govuk-!-font-size-14'>View projects list</a></div>" +
      "</div>";
  }

  // function used for number formatting (100000 becomes 100,000)
  function addCommas(nStr) {
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    x2 = x.length > 1 ? '.' + x[1] : '';
    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ',' + '$2');
    }
    return x1 + x2;
  }
  //Create the main map tiles for leaflet
  // Please note, the access token is restricted to FCDO domains only
  var layer = L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
    attribution: '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
    tileSize: 512,
    maxZoom: 18,
    zoomOffset: -1,
    id: 'mapbox/streets-v11',
    accessToken: 'pk.eyJ1IjoiaWF0aS1mZWVkYmFjayIsImEiOiJja3ZhajZ5aWUzOHMwMm9scG9qZ3Z3ZWVqIn0.rKZT_TovQOJoAi6Nt-q7Ag'
  });
  // Create a blank array that will hold the country list for drawing border polygons
  var countryList = [];
  // Set the zoom level based on the type of map
  if (mapType == 'country') {
    if (countryBounds[window.countryCode][2] != null) {
      zoomFactor = countryBounds[window.countryCode][2];
    }
    else {
      zoomFactor = 6;
    }
    // Create the main leaflet map based on type of map
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
    if(window.countryCode != 'SO') {
      countryList.push(mapBorder);
    }
  }
  else if (mapType == 'location') {
    map = new L.Map('countryMap', {
      center: new L.LatLng(7.79, 21.28),
      zoom: 2,
      layers: [layer]
    });
    $.each(countryMapData, function (i, v) {
      var calculatedOpacity = calculateOpacity(v.extra.budget, maxBudget);
      var fOpacity = 0.8;
      if (v.extra.id == 'SO') {
        calculatedOpacity = 0;
        fOpacity = 0;
      }
      
      var tempMapBorder = {
        "type": "Feature",
        "properties": {
          "popupContent": getPopupHTML(v.extra),
          "style": {
            stroke: true,
            weight: 1,
            color: "white",
            opacity: calculatedOpacity,
            fillColor: calculateBrightness(v.extra.budget, maxBudget),
            fillOpacity: fOpacity
          }
        },
        "geometry": {
          "type": v.geometry.type,
          "coordinates": v.geometry.coordinates
        }
      };
      countryList.push(tempMapBorder);
    });
    var info = L.control();

    info.onAdd = function (map) {
      this._div = L.DomUtil.create('div', 'info');
      this.update();
      return this._div;
    };

    info.update = function (props) {
      this._div.innerHTML = '<span>Total Country Project Budget for ' + finYear + ': £' + TotalCountryBudget + '</span>';
    };

    info.addTo(map);
  }
  else if (mapType == 'project') {
    if (countryCount > 1 || regionCount > 0) {
      map = new L.Map('countryMap', {
        center: new L.LatLng(7.79, 21.28),
        zoom: 1,
        layers: [layer]
      });
    }
    else if (countryCount == 1) {
      if (countryBounds[$('#countryCode').val()][2] != null) {
        zoomFactor = countryBounds[$('#countryCode').val()][2];
      }
      else {
        zoomFactor = 6;
      }
      // Create the main leaflet map based on type of map
      map = new L.Map('countryMap', {
        center: new L.LatLng(countryBounds[$('#countryCode').val()][0], countryBounds[$('#countryCode').val()][1]),
        zoom: zoomFactor,
        layers: [layer]
      });
    }
    else {
      map = new L.Map('countryMap', {
        center: new L.LatLng(7.79, 21.28),
        zoom: 1,
        layers: [layer]
      });
    }
  }
  else if ($("#projectType").val() == 'region') {
    var bounds = regionBounds[$("#countryCode").val()];
    var boundary = new L.LatLngBounds(
      new L.LatLng(bounds.southwest.lat, bounds.southwest.lng),
      new L.LatLng(bounds.northeast.lat, bounds.northeast.lng)
    );
    map = new L.Map('countryMap', {
      zoom: 6,
      layers: [layer]
    });
    map.fitBounds(boundary);
    map.panInsideBounds(boundary);
    //The following piece of code cannot be used because not all region can be bound properly.
    // $.each(regionWiseCountryBounds,function(i,v){
    //   var tempMapBorder = {
    //         "type": "Feature",
    //         "properties": {
    //             "popupContent": window.countryName,
    //             "style": {
    //               stroke: true,
    //               weight: 1,
    //               color: "red",
    //               opacity: 1,
    //               fillColor: "#204B63",
    //               fillOpacity: 0.2
    //             }
    //         },
    //         "geometry": {
    //             "type": v.type,
    //             "coordinates": v.coordinates
    //         }
    //     };
    //     countryList.push(tempMapBorder);
    // });
  }
  else if ($("#projectType").val() == 'global') {
    map = new L.Map('countryMap', {
      center: new L.LatLng(7.79, 21.28),
      zoom: 1,
      layers: [layer]
    });
  }
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
  L.geoJSON(countryList, {
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
  $.each(mapMarkers, function (index, marker) {
    var dtUrl = "/projects/" + encodeURIComponent(marker['iati_identifier']).toString() + "/summary";
    var title = marker['title'];
    var prepAltText = 'Programme title: ' + title + '. Programme identifier: ' + marker['iati_identifier'] + '. Programme location on map: ' + marker['loc'];
    var tempMarker = L.marker(L.latLng(marker.geometry.coordinates[1], marker.geometry.coordinates[0]), {
      title: title,
      keyboard: true,
      alt: prepAltText
    });
    tempMarker.bindPopup("<a href='" + dtUrl + "'>" + title + " (" + marker['iati_identifier'] + ")</a>" + "<br />" + marker['loc']);
    markers.addLayer(tempMarker);
  });
  map.addLayer(markers);
});
