$(document).ready(function() {
    function reformCurrencyFormat(value){
        if(value.indexOf("G") > -1){
            var temp = value.replace("G","B");
            return temp;
        }
        else{
            return value;
        }
    }
    var chart2 = dc.rowChart("#top5Countries");
    var info = crossfilter(window.top5Countries);
    var dimentions = info.dimension(function(d){
        return d.name;
    });
    var grouping = dimentions.group().reduceSum(function(d) {return d.budget;});
    chart2
    .width(320)
    .height(420)
    //.height(280)
    .x(d3.scale.ordinal())
    .elasticX(true)
    .dimension(dimentions)
    .group(grouping)
    .title(function(d){return "Budget: £" + reformCurrencyFormat(d3.format(".4s")(d.value))})
    .ordering(function(t){return t.budget;})
    .cap(10)
    .ordinalColors(['#D8DCBF'])
    .xAxis().tickFormat(function(d){return "£" + d3.format(".2s")(d)}).ticks(4);

    chart2.on('renderlet', function(chart) {
        chart.selectAll("text").on("click", function (d) {
            var result = $.grep(window.top5Countries,function(e){return e.name == d.key});
            window.location.href = "countries/"+ result[0].code  + "/";
        });
    });

    chart2.render();

    var chart3 = dc.rowChart("#top5Sectors");
    var info2 = crossfilter(window.top5Sectors);
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
    .title(function(d){return "Budget: £" + reformCurrencyFormat(d3.format(".4s")(d.value))})
    .ordering(function(t){return t.budget;})
    .cap(10)
    .ordinalColors(['#D8DCBF'])
    .xAxis().tickFormat(function(d){return "£" + d3.format(".2s")(d)}).ticks(4);

    chart3.on('renderlet', function(chart) {
        chart.selectAll("text").on("click", function (d) {
            var result = $.grep(window.top5Sectors,function(e){return e.name == d.key});
            window.location.href = "sector/"+ result[0].code  + "/";
        });
    });

    chart3.render();
    $('rect').click(function(){
        console.log($(this).parent().parent().parent().parent().attr('id'));
        if($(this).parent().parent().parent().parent().attr('id') == 'top5Countries'){
            var temp = $(this).parent().children('text').text();
            var result = $.grep(window.top5Countries,function(e){return e.name == temp});
            window.location.href = "countries/"+ result[0].code  + "/";
        }
        else{
            var temp = $(this).parent().children('text').text();
            var result = $.grep(window.top5Sectors,function(e){return e.name == temp});
            window.location.href = "sector/"+ result[0].code  + "/"; 
        }
    });
});