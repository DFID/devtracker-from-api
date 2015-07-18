(function(global, undefined){


    // maximum budget is needed to work out budget percentage repartition value to produce heat map
    function getMaxBudget(countriesData){
        var maxFound=0;
        for (var countryDataIndex in countriesData){
            var countryData=countriesData[countryDataIndex];
            if (maxFound < countryData.budget){
                maxFound=countryData.budget;
            }
        }
        return(maxFound);
    }

    function calculateOpacity(country, max){
        return (country.budget / max) + 0.3
    }

    function calculateBrightness(country, max){
        return d3.rgb("#79A9D6").brighter(-(country.budget/max)*3).toString()
    }

    // function used for number formatting (100000 becomes 100,000)
    function addCommas(nStr){
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

    // creates the HTML for the popup when a country is clicked
    function getPopupHTML(countryData){
        var date = new Date();
        var currentFY = "";
        if (date.getMonth() < 3)
            currentFY = "FY" + (date.getFullYear() - 1) + "/" + date.getFullYear();
        else 
            currentFY = "FY" + date.getFullYear() + "/" + (date.getFullYear() + 1);
        return "" +
        "<div class='popup' style='min-width:350px;'>" +
        "   <h1><img class='flag' alt='Country Flag' src='" + countryData.flag + "' /> " + countryData.country + "</h1>"  +
        "   <div class='row'>" +
        "       <div class='six columns'>" +
        "           <div class='stat'>" +
        "               <h3>Country budget " + currentFY + "</h3>" +
        "           </div>"  +
        "       </div>" +
        "       <div class='six columns'>" +
        "           <div class='stat'>" +
        "              <h3>Number of projects</h3>" +
        "          </div>" +
        "       </div>"  +
        "   </div>" +
        "   <div class='row'>" +
        "       <div class='six columns'>" +
        "           <div class='stat'>" +
        "               <p>\u00A3" + addCommas(countryData.budget) + "</p>"  +
        "           </div>"  +
        "       </div>" +
        "       <div class='six columns'>" +
        "           <div class='stat'>" +
        "              <p>" + countryData.projects + "</p>"  +
        "          </div>" +
        "       </div>"  +
        "   </div>" +
        "   <div class='row'>" +
        "       <div class='six columns'>" +
        "           <div class='stat'><a href='/countries/" + countryData.id + "'>View country info</a></div>"  +
        "       </div>" +
        "       <div class='six columns'> " +
        "          <div class='stat'><a href='/countries/" + countryData.id + "/projects'>View projects list</a></div>"  +
        "        </div>"  +
        "   </div>" +
        "</div>";
    }

    function paintCountryPolygons(countriesData,polygonsData) {
        var maxBudget=getMaxBudget(countriesData); // computes the maximum budget between the countries. used to compute percentage values

        // creates the country polygons
        for (var countryDataIndex in countriesData) {
            var countryData=countriesData[countryDataIndex];
            if (countryData.budget>0){
                var multiVertices = new Array();
                for (var countryPolygonesDefArrayIndex=0; countryPolygonesDefArrayIndex<polygonsData[countryData.id].length; countryPolygonesDefArrayIndex++) {
                    var countryPolygoneDefString = polygonsData[countryData.id][countryPolygonesDefArrayIndex];
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
                    color: '#ffffff', /* border color */
                    weight: 1, /* stroke width in pixels */
                    fill:true,
                    fillColor: calculateBrightness(countryData, maxBudget),//"#204B63",
                    fillOpacity: 1//calculateOpacity(countryData, maxBudget)
                });

                multiPolygon.addTo(map); /* finally addes the polygon to the map */

                /* polygon events: click (popup), mouseover, mouseout */
                multiPolygon.bindPopup(getPopupHTML(countryData), { minWidth: 400 }); // this option seams to doesn't work
                /* paint the country red on mouseover */
                multiPolygon.on("mouseover", function(countryData){
                    return(function(e){
                        this.setStyle({
                            fillColor: "#333"
                        });

                        countryhover
                            .setLatLng(e.latlng)
                            .setContent(countryData.country)
                            .openOn(map);

                        $(countryhover._wrapper).addClass("quickpop")
                    })
                }(countryData),multiPolygon);

                /* re-paint the country with its heat color on mouse out */
                multiPolygon.on("mouseout", function(countryData){
                    return(function(e){
                        this.setStyle({
                            fillColor: calculateBrightness(countryData, maxBudget)
                        });
                    })
                }(countryData),multiPolygon);
            }

            map.on('zoomend', function(e) {
                var mapElement = document.getElementById("map");

                if ("undefined" != typeof mapElement){
                    var svgElements = mapElement.getElementsByTagName("svg");
                    if (svgElements.length > 0){
                        var objectsPanes = svgElements[0].parentNode.parentNode.childNodes; /* easier to get to that way */
                        for (var i=0; i<objectsPanes.length; i++){
                            var pane=objectsPanes[i];
                            pane.style.zIndex=3;
                        }
                    }
                }
            });
        }
    }


    // creates a new map and centers it somewhere in the indian ocean
    var map = L.map('map').setView([0, 60], 2);

    // map.addLayer(new L.Google('ROADMAP'))
    // creates a tile layer with the tiles hosted in mapbox
    L.tileLayer("http://devtracker.dfid.gov.uk/v2/dfid/{z}/{x}/{y}.png", {
                            minZoom: 2,
                            maxZoom: 4,
                            attribution: ''
                        }).addTo(map);

    var countryhover = L.popup({
        closeButton: false,
        offset: new L.Point(0, -10)
    });

    paintCountryPolygons(countriesData,polygonsData);
})(this)