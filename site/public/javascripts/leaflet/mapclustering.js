

function createMapWithCoordinates(coordinatesArray){
    var geoJson = {
        type: "FeatureCollection",
        features: []
    };


    for(var i = 0; i < coordinatesArray.length; i++){
        var coordinates = coordinatesArray[i]
        geoJson.features.push({
           "type":"Feature",
           "id":"2",
           "properties":{
              "address":"2"
           },
           "geometry":{
              "type":"Point",
              "coordinates":[
                 coordinates.split(",")[0],
                 coordinates.split(",")[1]
              ]
           }
        })
    }


        var map = L.map('map');

        // creates a tile layer
        L.tileLayer("http://devtracker.dfid.gov.uk/v2/dfid/{z}/{x}/{y}.png", {
            minZoom: 1,
            maxZoom: 10,
            attribution: ''
        }).addTo(map);


    var geoJsonData = geoJson;


    var markers = new L.MarkerClusterGroup();

                    console.log(markers);
    var geoJsonLayer = L.geoJson(geoJsonData, {
                    onEachFeature: function (feature, layer) {
                        //layer.bindPopup(feature.properties.address);  uncommenting this will add a 'feature' pop-up to the point
                    }
                });
    markers.addLayer(geoJsonLayer);
    map.addLayer(markers);
    console.log(geoJsonData);
    map.fitBounds(markers.getBounds());

    //return geoJsonData;
}
