(function($, d3, global, undefined){

    var defaultColors = ["#4F2938",
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
                         "#70A09A"];

    function bar(elSelector, data, yFormat, yLabel, xLabel, colors){

        colors = colors || defaultColors;
        var margin = {top: 20, right: 0, bottom: 20, left: 50};
        var width = $(elSelector).width() - margin.left - margin.right;
        var height = $(elSelector).height() - margin.top - margin.bottom;

        var color = d3.scale.ordinal().range(colors);

        // element labels
        var elementNames = data[0].slice(1);

        // data array without element labels
        var dataValues = data.slice(1)

        // x axis scale
        var x0 = d3.scale.ordinal()
            .rangeRoundBands([0, width], 1 / data[0].length) // padding = 1 / group size  + 1
            .domain(dataValues.map(function(d) { return d[0]; })); // x axis labels

        // group elements scale
        var x1 = d3.scale.ordinal()
            .rangeRoundBands([0, x0.rangeBand()]) // range = 0 to group size
            .domain(elementNames); // x sub labels (element in group)

        var yDomain = [
            d3.min([0, d3.min(dataValues, function(d) { return d3.min(d.slice(1)); } )]), 
            d3.max(dataValues, function(d) { return d3.max(d.slice(1)); } )
        ];

        // y axis scale
        var y = d3.scale.linear()
                        .range([height, 0])
                        .domain(yDomain);

        var xAxis = d3.svg.axis()
                          .scale(x0)
                          .orient("bottom")
                          .tickSize(0);
        var yAxis = d3.svg.axis()
                          .scale(y)
                          .orient("left")
                          .tickFormat(d3.format(yFormat))
                          .ticks(5)
                          .tickSize( -width - margin.left - margin.right, 0);

        // create svg
        var svg = d3.select(elSelector)
                    .append("svg")
                        .attr("width", width + margin.left + margin.right)
                        .attr("height", height + margin.top + margin.bottom)
                        .append("g")
                            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis)
            .append("text")
                .attr("text-anchor", "end")
                .attr("x", width)
                .attr("dy", "-0.25em")
                .text(xLabel);

        svg.append("g")
            .attr("class", "y axis")
            .call(yAxis)
            .append("text")
                .text(yLabel);

        var group = svg.selectAll(".group")
            .data(dataValues)
            .enter().append("g")
                .attr("class", "group")
                .attr("transform", function(d) { return "translate(" + x0(d[0]) + ",0)"; });

        group.selectAll("rect")
            .data(function(d) { return d.slice(1); }) // values without group label
            .enter().append("rect")
                .attr("width", x1.rangeBand())
                .attr("x", function(d, i) { return x1(elementNames[i]); })
                .attr("y", function(d) { 
                    if(yDomain[0] < 0) {
                        if(d > 0) {
                          return y(d);
                        } else {
                          return y(0);
                        }
                    } else {
                        return y(d);
                    }
                })
                .attr("height", function(d) { 
                    if(yDomain[0] < 0) {
                        if(d > 0) {
                            return y(0) - y(d);
                        } else {
                            return y(d) - y(0);
                        }
                    } else {
                        return height - y(d);
                    }

                })
                .attr("title", function(d){ return d})
                .style("fill", function(d, i) { return color(i); })
                .append("title").text("£")
                .append("title").text(function(d){return d})


   }


    global.charts = global.charts || {}
    global.charts.bar = bar

})(jQuery, d3, this)