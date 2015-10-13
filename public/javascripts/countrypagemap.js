(function(global, undefined){

     //helpers for the markers
    function markerOptions() {
        var geojsonMarkerOptionsStuff = {
            radius: 6,
            fillColor: "#a04567",
            color: "#000",
            weight: 1,
            opacity: 1,
            fillOpacity: 0.8
        };
        return geojsonMarkerOptionsStuff
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
    //TODO - get some logic to determine project type
    //projectType = "country";
    countryCode = "BD";
    countryName = "Bangladesh";
    var map;
 
 // TODO Remove alert
 //   alert("country map" + projectType);

    var osmHOT = L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
                              maxZoom: 19,
                              attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>'
                             });


    if (projectType == "global") {

        map = new L.Map('countryMap', {
            center: new L.LatLng(7.79,21.28), 
            zoom: 1,
            layers: [osmHOT]
        });

        //map.addLayer(new L.Google('ROADMAP'));


    } else if (countryName && countryCode) {  
        map = new L.Map('countryMap', {
            center: new L.LatLng(countryBounds[countryCode][0], countryBounds[countryCode][1]), 
            zoom: 6,
            layers: [osmHOT]
        });
        //map.addLayer(new L.Google('ROADMAP'));

    } else if (countryCode) {
        var bounds = regionBounds[countryCode];
        var boundary = new L.LatLngBounds(
            new L.LatLng(bounds.southwest.lat, bounds.southwest.lng),
            new L.LatLng(bounds.northeast.lat, bounds.northeast.lng)            
        );

        map = new L.Map('countryMap',
            {
                layers: [osmHOT]
            });
        //map.addLayer(new L.Google('ROADMAP'))
        map.fitBounds(boundary);
        map.panInsideBounds(boundary);
    } else {
        $('#countryMap').hide();
        $('#countryMapDisclaimer').hide();
    }

    //get country locations from OIPA API


    // create the geopoints if any are defined
    if(map) {
        //alert("start processing datapoints");
        var url = "http://dfid-oipa.zz-clients.net/api/activities?format=json&reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=" + countryCode + "&fields=title,reporting_organisation,iati_identifier,locations&page_size=";

        $.getJSON(url, function (iati) {
        //iterate through every activity
            iati.results.forEach(function (d) {
                var iatiIdentifier = d.iati_identifier;
                var dtUrl = "http://devtracker.dfid.gov.uk/projects/" + iatiIdentifier;
                var reportingOrg = d.reporting_organisation.organisation.code;
                var reportingOrgName = d.reporting_organisation.organisation.name.narratives[0].text;
                var title = (d.title.narratives != null) ? d.title.narratives[0].text : "";
                
                //iterate over each location
                d.locations.forEach(function (p) {
                    var latlng = L.latLng(p.point.coordinates);
                    var marker = new L.circleMarker(latlng, markerOptions());
                    console.log(reportingOrg);
                    
                    //create popup text
                    var locationName = p.name.narratives[0].text;
                    marker.bindPopup("<a href='" + dtUrl + "'>" + title + "</a>" + "<br />" + locationName);
                    
                    //add to the right layer (by reporting org)
                    //addReportingOrgLayer(reportingOrg, marker);
                    map.addLayer(marker);
                });
            });
        });


        // var markers = new L.MarkerClusterGroup({ 
        //     spiderfyOnMaxZoom: false, 
        //     showCoverageOnHover: false,
        //     singleMarkerMode: true,
        //     iconCreateFunction: function(cluster) {
        //         var count = cluster.getChildCount();
        //         var additional = ""
        //         if(count > 99) {
        //             count = "+";
        //             additional = "large-value";
        //         }

        //         return new L.DivIcon({ html: '<div class="marker cluster ' + additional + '">' + count+ '</div>' });
        //     } 
        // });

        // markers.on('clusterclick', function (a) {
        //  var atMax = a.target._zoom == a.target._maxZoom
        //  if(atMax) {
        //     var clusterLocations = [];
        //     for(var i = 0; i < a.layer._markers.length; i++) {
        //         clusterLocations.push(a.layer._markers[i].options.data)
        //     }
            
        //     var html = buildClusterPopupHtml(clusterLocations)
        //     var popup = L.popup()
        //                  .setLatLng(a.layer._latlng)
        //                  .setContent(html)
        //                  .openOn(map);
        //  }
        // });

        // for(var i = 0; i < locations.length; i++){
        //     var location = locations[i];
        //     //alert(location.point.coordinates[0]);
        //     //var latlng   = new L.LatLng(location.latitude, location.longitude)
        //     var latlng   = new L.LatLng(location.point.coordinates[0],location.point.coordinates[1]);
        //     var marker   = new L.Marker(latlng, { 
        //         title: location.name.narratives[0].text, 
        //         data:  location
        //     });

        //     // mapType is a global variable that is used to
        //     switch(mapType) {
        //         case "country": 
        //             marker.bindPopup(buildClusterPopupHtml([location]))
        //             break;
        //         case "project": 
        //             marker.bindPopup(buildMarkerPopupHtml(location))
        //             break;
        //     }
            
        //     markers.addLayer(marker);
        // }

        // map.addLayer(markers);
    }

})(this)
