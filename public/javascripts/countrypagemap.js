$(document).ready(function() {
    (function(global, undefined){
        //The following method is created based on Ray casting algorithm
        //Source: https://github.com/substack/point-in-polygon
        //Source: https://wrf.ecse.rpi.edu//Research/Short_Notes/pnpoly.html
        function isMarkerInsidePolygon(marker, poly) {
            var polyPoints = poly.getLatLngs();
            var x = marker.getLatLng().lat, y = marker.getLatLng().lng;
            var inside = false;
            for(var a = 0; a < polyPoints.length; a++){
                for (var i = 0, j = polyPoints[a].length - 1; i < polyPoints[a].length; j = i++) {
                    var xi = polyPoints[a][i].lat, yi = polyPoints[a][i].lng;
                    var xj = polyPoints[a][j].lat, yj = polyPoints[a][j].lng;
                    var intersect = ((yi > y) != (yj > y))
                        && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
                    if (intersect){
                        inside = !inside;
                    }
                }
            }
            return inside;
        };
         //helpers for the markers
        function markerOptions(id,title) {
            var geojsonMarkerOptionsStuff = {
                radius: 6,
                fillColor: "#a04567",
                color: "#000",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.8,
                id:id,
                title:title
            };
            return geojsonMarkerOptionsStuff
        }

        function buildClusterPopupHtml(locations) {
            //alert(iatiTitle + iatiId);
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

        var osmHOT = L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
                                  maxZoom: 10,
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
        } else if (countryName && countryCode) {  
            
            if (countryBounds[countryCode][2] != null){
                zoomFactor = countryBounds[countryCode][2];
                console.log(zoomFactor);
                }
                else zoomFactor = 6;

            map = new L.Map('countryMap', {
                center: new L.LatLng(countryBounds[countryCode][0], countryBounds[countryCode][1]), 
                zoom: zoomFactor,  
                layers: [mapBox]
            });
        } else if (countryCode) {
            var bounds = regionBounds[countryCode];
            var boundary = new L.LatLngBounds(
                new L.LatLng(bounds.southwest.lat, bounds.southwest.lng),
                new L.LatLng(bounds.northeast.lat, bounds.northeast.lng)            
            );

            map = new L.Map('countryMap',
                {
                    layers: [mapBox]
                });
            map.fitBounds(boundary);
            map.panInsideBounds(boundary);
        } else {
            $('#countryMap').hide();
            $('#countryMapDisclaimer').hide();
        }

        //get country locations from OIPA API

        //Draw a polygon on the map to bound the exact country position
        var multiVertices = new Array();
        for (var countryPolygonesDefArrayIndex=0; countryPolygonesDefArrayIndex<polygonsData[countryCode].length; countryPolygonesDefArrayIndex++) {
            var countryPolygoneDefString = polygonsData[countryCode][countryPolygonesDefArrayIndex];
            var verticesDefArray = countryPolygoneDefString.split(" ");
            var vertices = new Array();
            for (var vertexDefStringIndex=0; vertexDefStringIndex<verticesDefArray.length; vertexDefStringIndex++) {
                var vertexDefString = verticesDefArray[vertexDefStringIndex].split(",");
                var longitude=vertexDefString[0];
                var latitude=vertexDefString[1];
                var latLng=new L.LatLng(latitude,longitude);
                vertices[vertices.length]=latLng;
            }
            multiVertices[multiVertices.length]=vertices;
        }
        var multiPolygon = L.multiPolygon(multiVertices,{
            stroke: true, /* draws the border when true */
            color: 'red', /* border color */
            weight: 1, /* stroke width in pixels */
            fill:true,
            fillColor: '#204B63',//"#204B63",
            fillOpacity: 0.4
        });
        multiPolygon.addTo(map);

        // create the geopoints if any are defined
        if(map) {
            //alert("start processing datapoints");
            var url = window.baseUrl + "activities/?format=json&reporting_org_identifier="+window.reportingOrgs+"&hierarchy=1&recipient_country=" + countryCode + "&fields=title,iati_identifier,locations&page_size=500&activity_status=2";
            console.log(url);
            $.getJSON(url, function (iati) {
            $('.modal_map_markers').show();
            //set up markerCluster
            var markers = new L.MarkerClusterGroup({ 
                spiderfyOnMaxZoom: true, 
                showCoverageOnHover: false,
                singleMarkerMode: true,
                maxClusterRadius: 40,
                removeOutsideVisibleBounds: false,
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
             //alert("clusterclick" +  a.target._zoom + " "  + a.target._maxZoom);
             var atMax = a.target._zoom == a.target._maxZoom
             if(atMax) {
                var clusterLocations = [];
                for(var i = 0; i < a.layer._markers.length; i++) {
                    clusterLocations.push(a.layer._markers[i].options);
                }
                
                var html = buildClusterPopupHtml(clusterLocations)
                var popup = L.popup()
                             .setLatLng(a.layer._latlng)
                             .setContent(html)
                             .openOn(map);
             }
            });


            //iterate through every activity
                iati.results.forEach(function (d) {
                    var iatiIdentifier = d.iati_identifier;
                    var dtUrl = "https://devtracker.fcdo.gov.uk/projects/" + iatiIdentifier;
                    var title = (d.title.narratives != null) ? d.title.narratives[0].text : "";
                    //iterate over each location
                    d.locations.forEach(function (p) {
                        try{
                            var latlng = L.latLng(p.point.pos.latitude,p.point.pos.longitude);
                            var marker = new L.circleMarker(latlng, markerOptions(iatiIdentifier,title));
                            //create popup text
                            var locationName = p.name.narratives[0].text;
                            marker.bindPopup("<a href='" + dtUrl + "'>" + title + " (" + iatiIdentifier + ")</a>" + "<br />" + locationName);
                            //if(tempBreaker == 0 && (p.administrative[0].code == countryCode || p.name[0].narratives[0].text)){
                            //if(tempBreaker == 0 && (p.name[0].narratives[0].text.includes(countryName) || p.description[0].narratives[0].text.includes(countryName))){
                                if(isMarkerInsidePolygon(marker,multiPolygon)){
                                //add to the map layer
                                markers.addLayer(marker);
                            }
                        }
                        catch(e){
                            console.log(iatiIdentifier);
                            console.log("variable doesn't exist");
                        }
                    });
                });

                map.addLayer(markers);
            }).done(function(){
                $('.modal_map_markers').hide();
            });
        }

    })(this)
});