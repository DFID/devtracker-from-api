(function($, d3, global, undefined){

    var color = d3.scale.ordinal().range([
        "#4F2938",
        "#EABB7E",
        "#DB7E64",
        "#2B6367",
        "#244E66",
        "#B3424A",
        "#437BAB",
        "#D8DCBF",
        "#A5BBAE",
        "#8CB6DA",
        "#FFD991",
        "#70A09A"
    ]);

    function colourFor(selector) {
        return color(selector)
    }

    function donut(elSelector, data, valueFn, paletteFn, formatFn){
        formatFn = formatFn || valueFn

        var width = 200;

        // items are square s
        var height = width;

        var radius = Math.min(width, height) / 2;

        var arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(radius - 50);
        var pie = d3.layout.pie().sort(null).value(valueFn);
        var svg = d3.select(elSelector).append("svg")
                    .attr("width", width)
                    .attr("height", height)
                    .append("g")
                        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

        svg.selectAll(".arc").data(pie(data)).enter().append("g")
            .attr("class", "arc")
            .append("path")
                .attr("d", arc)
                .style("fill", function(d) { return colourFor(paletteFn(d.data)); })
                .append("title")
                    .text( function(d) { return paletteFn(d.data) + ": " + formatFn(d.data)})

    }

    function donutLegend(elSelector, itSelector, size, data, paletteFn){

        d3.select(elSelector).selectAll(itSelector).data(data).insert("svg")
            .attr("width", function() { return $(this).width() })
            .attr("height", function() { return $(this).height() })
            .append("rect")
                .attr("width", "100%")
                .attr("height", 56)
                .attr("width", 10)
                .style("fill", function(d) {
                    return colourFor(paletteFn(d));
                });
    }

    global.charts = global.charts || {}
    global.charts.donut = donut
    global.charts.donutLegend = donutLegend
    global.charts.colourFor = colourFor

})(jQuery, d3, this)
