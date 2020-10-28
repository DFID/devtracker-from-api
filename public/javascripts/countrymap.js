(function(global, undefined){

    function buildMarkerPopupHtml(location_title) {
        return [
            "<div class='location-popup'>",
                "<div class='row'>", 
                    "<div class='four columns location-label'> Name </div>", 
                    "<div class='eight columns'>", location_title, "</div>",
                "</div>",
                //"<div class='row'>", 
                //    "<div class='four columns location-label'> Precision </div>", 
                //    "<div class='eight columns'>", location.precision, "</div>",
                //"</div>",
                //"<div class='row'>", 
                //    "<div class='four columns location-label'> Type </div>", 
                //    "<div class='eight columns'>", location["type"], "</div>",
                //"</div>",
            "</div>"
        ].join("")
    }

    function buildClusterPopupHtml(locations) {
        var items = [];
        for(var i = 0; i < locations.length; i++) {
            var location = locations[i];
            items.push([
                "<div class='row'>", 
                    "<div class='five columns location-label'>", 
                        "<a href='/projects/", location.id ,"'>", location.id, "</a>",
                    "</div>", 
                    "<div class='seven columns'>", location.title, "</div>",
                "</div>"
            ].join(""));
        }

        return [
            "<div class='location-popup large'>",
                items.join(""),
            "</div>"
        ].join("")
    }

    var countryName = $("#countryName").val();
    var countryCode = $("#countryCode").val();
    var projectType = $("#projectType").val();
    var map;
 
 // TODO Remove alert
    //alert("country map" + projectType);

    var osmHOT = L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
                              maxZoom: 19,
                              attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>'
                             });
    
    var mqTilesAttr = 'Tiles &copy; <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img alt="MapQuest Logo" src="http://developer.mapquest.com/content/osm/mq_logo.png" />';
    var mapQuestOSM = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/{type}/{z}/{x}/{y}.png', {
        options: {
            subdomains: '1234',
            type: 'osm',
            attribution: 'Map data ' + L.TileLayer.OSM_ATTR + ', ' + mqTilesAttr
        }
    });

    var cartoDB = L.tileLayer('http://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'
    });
    // Please note, the access token is restricted to FCDO domains only
    var mapBox = L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}', {
        attribution: '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
        tileSize: 512,
        maxZoom: 18,
        zoomOffset: -1,
        id: 'mapbox/streets-v11',
        accessToken: 'pk.eyJ1IjoiaWF0aS1mZWVkYmFjayIsImEiOiJja2d0Njl2MWkwOG92MnhwMHhmOHR3MXQyIn0.bXjLLa0rGrsIzDNS1E5H1w'
        });
    if (projectType == "global") {

        map = new L.Map('countryMap', {
            center: new L.LatLng(7.79,21.28), 
            zoom: 1,
            layers: [mapBox]
        });

        //map.addLayer(new L.Google('ROADMAP'));


    } else if (projectType == "country" && countryName && countryCode) {  
        map = new L.Map('countryMap', {
            center: new L.LatLng(countryBounds[countryCode][0], countryBounds[countryCode][1]), 
            zoom: countryBounds[countryCode][2] || 6,
            layers: [mapBox]
        });
        //map.addLayer(new L.Google('ROADMAP'));

    } else if (projectType == "region" && countryCode) {
        var bounds = regionBounds[countryCode];
        var boundary = new L.LatLngBounds(
            new L.LatLng(bounds.southwest.lat, bounds.southwest.lng),
            new L.LatLng(bounds.northeast.lat, bounds.northeast.lng)            
        );

        map = new L.Map('countryMap',
            {
                layers: [mapBox]
            });
        //map.addLayer(new L.Google('ROADMAP'))
        map.fitBounds(boundary);
        map.panInsideBounds(boundary);
    } else {
        $('#countryMap').hide();
        $('#countryMapDisclaimer').hide();
    }

    // create the geopoints if any are defined
    if(map && global.locations) {
        //alert("start processing datapoints");

        var markers = new L.MarkerClusterGroup({ 
            spiderfyOnMaxZoom: false, 
            showCoverageOnHover: false,
            singleMarkerMode: true,
            iconCreateFunction: function(cluster) {
                var count = cluster.getChildCount();
                var additional = ""
                if(count > 99) {
                    count = "+";
                    additional = "large-value";
                }

                return new L.DivIcon({ html: '<div class="marker cluster ' + additional + '">' + count+ '</div>' });
            } 
        });

        markers.on('clusterclick', function (a) {
         var atMax = a.target._zoom == a.target._maxZoom
         if(atMax) {
            var clusterLocations = [];
            for(var i = 0; i < a.layer._markers.length; i++) {
                clusterLocations.push(a.layer._markers[i].options.data)
            }
            
            var html = buildClusterPopupHtml(clusterLocations)
            var popup = L.popup()
                         .setLatLng(a.layer._latlng)
                         .setContent(html)
                         .openOn(map);
         }
        });
        var markerArray = [];
        for(var i = 0; i < locations.length; i++){
            var location = locations[i];
            //console.log(location.point.point.latitude);
            //var latlng   = new L.LatLng(location.latitude, location.longitude)
            var latlng, marker_title;
            try {
                marker_title = location.name[0].narratives[0].text;
            }
            catch(e){
                marker_title = ProjectTitle;   
            }
            try {
                latlng = new L.LatLng(location.point.pos.latitude,location.point.pos.longitude);
                var marker = new L.Marker(latlng, { 
                    title: marker_title, 
                    //data:  location
                });
                switch(mapType) {
                    case "country": 
                        marker.bindPopup(buildClusterPopupHtml([location]))
                        break;
                    case "project": 
                        marker.bindPopup(buildMarkerPopupHtml(marker_title))
                        break;
                }
                markers.addLayer(marker);
                markerArray.push(marker);
                if(projectType == "global"){
                    if(i==locations.length-1){
                        var group3 = L.featureGroup(markerArray);
                        map.fitBounds(group3.getBounds());
                        if(map.getZoom() > 12){
                            map.setZoom(map.getZoom() - 9);
                        }
                    }
                }
            }
            catch(e){
                latlng = new L.LatLng(0,0);   
            }
            //var latlng   = new L.LatLng(location.point.pos.latitude,location.point.pos.longitude);
            /*var marker   = new L.Marker(latlng, { 
                title: location.name[0].narratives[0].text, 
                data:  location
            });*/

            // mapType is a global variable that is used to
            /*switch(mapType) {
                case "country": 
                    marker.bindPopup(buildClusterPopupHtml([location]))
                    break;
                case "project": 
                    marker.bindPopup(buildMarkerPopupHtml(location))
                    break;
            }*/
            
            //markers.addLayer(marker);
        }

        map.addLayer(markers);
    }

})(this)
