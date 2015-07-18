(function($, d3, global, undefined){

    function progressBar(elSelector, data, valueFn, labelFn, textFn){

        var margin = {top: 10, right: 200, bottom: 10, left: 10};
        var width = $(elSelector).width() - margin.left - margin.right;
        var height = $(elSelector).height() - margin.top - margin.bottom;
        var size = 30;
        var thickSize = 3;

        var x = d3.scale.linear().domain([valueFn(data[0]), valueFn(data[2])]).range([0, width]);
        var currentValue = valueFn(data[1]);
        if (currentValue > valueFn(data[2]))   {
            currentValue = valueFn(data[2]);
        }
        if (currentValue < valueFn(data[0]))   {
            currentValue = valueFn(data[0]);
        }

        var percent = 0
        if ((valueFn(data[2]) - valueFn(data[0])) != 0){
            percent = (((currentValue - valueFn(data[0])) / (valueFn(data[2]) - valueFn(data[0]))) * 100.0).toFixed(2)
        }

        var percentText =  percent + "%";
        if (textFn(data[1]) != null && textFn(data[1]) != "") {
            percentText = " (" + percentText  + ")";
        }

        var svg = d3.select(elSelector)
                .append("svg")
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
                .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        // background
        svg.append("rect")
            .attr("class", "max")
            .attr("x", 0)
            .attr("y", (height - size ) / 2)
            .attr("width", width)
            .attr("height", size);

        svg.append("rect")
            .attr("class", "max")
            .attr("x", width - thickSize)
            .attr("y", 0)
            .attr("width", thickSize)
            .attr("height", (height + size ) / 2);

        // progress
        svg.append("rect")
            .attr("class", "bar")
            .attr("x", 0)
            .attr("y", (height - size ) / 2)
            .attr("width", x(currentValue))
            .attr("height", size);

        svg.append("rect")
            .attr("class", "bar")
            .attr("x", x(currentValue) - thickSize)
            .attr("y", (height - size ) / 2)
            .attr("width", thickSize)
            .attr("height", (height + size ) / 2);

        svg.append("text")
            .attr("class", "label")
            .attr("dy", "1em")
            .text(labelFn(data[0]) + "\n")
            .append("tspan")
                .attr("x", 0)
                .attr("dy", "1.25em")
                .attr("class", "text")
                .text(textFn(data[0]));

        svg.append("text")
            .attr("class", "label")
            .attr("transform", "translate(" + (x(currentValue) + 5) + "," + 3 * height / 4 + ")")
            .text(labelFn(data[1]))
            .append("tspan")
                .attr("x", 0)
                .attr("dy", "1.25em")
                .attr("class", "text")
                .text(textFn(data[1]))
                .append("tspan")
                    .attr("class", "percent")
                    .text(percentText);

        svg.append("text")
            .attr("class", "label")
            .attr("transform", "translate(" + (width + 5) + ",0 )")
            .attr("dy", "1em")
            .text(labelFn(data[2]))
            .append("tspan")
                .attr("x", 0)
                .attr("dy", "1.25em")
                .attr("class", "text")
                .text(textFn(data[2]));
    }

    global.charts = global.charts || {}
    global.charts.progressBar = progressBar

})(jQuery, d3, this)