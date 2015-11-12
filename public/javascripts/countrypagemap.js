(function(global, undefined){

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
    //TODO - get some logic to determine project type
    //projectType = "country";
    //countryCode = "BD";
    //countryName = "Bangladesh";
    var map;
 
 // TODO Remove alert
 //   alert("country map" + projectType);

    var osmHOT = L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
                              maxZoom: 10,
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
        
        if (countryBounds[countryCode][2] != null)
            zoomFactor = countryBounds[countryCode][2];
            else zoomFactor = 6;

        map = new L.Map('countryMap', {
            center: new L.LatLng(countryBounds[countryCode][0], countryBounds[countryCode][1]), 
            zoom: zoomFactor,  
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
        var url = "http://dfid-oipa.zz-clients.net/api/activities?format=json&reporting_organisation=GB-1&hierarchy=1&related_activity_recipient_country=" + countryCode + "&fields=title,iati_identifier,locations&page_size=500";

        $.getJSON(url, function (iati) {

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
                //console.log(a.layer._markers[i].options);
                //console.log(clusterLocations);
            }
            
            var html = buildClusterPopupHtml(clusterLocations)
            //console.log(html);
            var popup = L.popup()
                         .setLatLng(a.layer._latlng)
                         .setContent(html)
                         .openOn(map);
         }
        });


        //iterate through every activity
            iati.results.forEach(function (d) {
                var iatiIdentifier = d.iati_identifier;
                var dtUrl = "http://devtracker.dfid.gov.uk/projects/" + iatiIdentifier;
                var title = (d.title.narratives != null) ? d.title.narratives[0].text : "";
                //console.log(iatiIdentifier);
                
                //iterate over each location
                d.locations.forEach(function (p) {
                    var latlng = L.latLng(p.point.pos.latitude,p.point.pos.longitude);
                    var marker = new L.circleMarker(latlng, markerOptions(iatiIdentifier,title));
                    //console.log(p.point.point.longitude,p.point.point.latitude);
                    
                    //create popup text
                    var locationName = p.name[0].narratives[0].text;
                    marker.bindPopup("<a href='" + dtUrl + "'>" + title + " (" + iatiIdentifier + ")</a>" + "<br />" + locationName);
                    
                    //marker.bindPopup(buildClusterPopupHtml(marker.options))
                    
                    //add to the map layer
                    markers.addLayer(marker);
                });
            });

            map.addLayer(markers);
        });
    }

})(this)
