$(document).ready(function() {
    var chart2 = dc.rowChart("#top5Countries");


    var info = crossfilter(top5Countries);
    var dimentions = info.dimension(function(d){
        return d.name;
    });
    var grouping = dimentions.group().reduceSum(function(d) {return d.budget;});
    chart2
    .width(320)
    .height(420)
    .x(d3.scale.ordinal())
    .elasticX(true)
    .dimension(dimentions)
    .group(grouping)
    .title(function(d){return "Budget: £" + d3.format(".4s")(d.value)})
    .ordering(function(t){return t.budget;})
    .cap(10)
    .ordinalColors(['#D8DCBF'])
    .xAxis().tickFormat(function(d){return "£" + d3.format(".2s")(d)}).ticks(4);

    chart2.on('renderlet', function(chart) {
        chart.selectAll("text").on("click", function (d) {
            var result = $.grep(top5Countries,function(e){return e.name == d.key});
            window.location.href = "countries/"+ result[0].code  + "/";
        });
    });

    chart2.render();

    var chart3 = dc.rowChart("#top5Sectors");
    var info2 = crossfilter(top5Sectors);
    var dimentions2 = info2.dimension(function(d){
        return d.name;
    });
    var grouping2 = dimentions2.group().reduceSum(function(d) {return d.budget;});
    chart3
    .width(340)
    .height(420)
    .x(d3.scale.ordinal())
    .elasticX(true)
    .dimension(dimentions2)
    .group(grouping2)
    .title(function(d){return "Budget: £" + d3.format(".4s")(d.value)})
    .ordering(function(t){return t.budget;})
    .cap(10)
    .ordinalColors(['#D8DCBF'])
    .xAxis().tickFormat(function(d){return "£" + d3.format(".2s")(d)}).ticks(4);

    chart3.on('renderlet', function(chart) {
        chart.selectAll("text").on("click", function (d) {
            var result = $.grep(top5Sectors,function(e){return e.name == d.key});
            window.location.href = "sector/"+ result[0].code  + "/";
        });
    });

    chart3.render();
});