
var circleGraph = {

	drawGlobalProjectsGraph : function(divId, r, labels) {

        var w = $(divId).width();
        var h = $(divId).height();

        var circleShiftX = w / 2 - r;
        var circleShiftY = h / 2 - r - 50; // 50 - additional shift, circle is not centered on Y axis

        var g = d3.select(divId)
                    .append("svg")
                    .append("g")
                    .attr("transform", "translate(" + circleShiftX + ", " + circleShiftY + ")");

        g.append("circle")
            .style("fill", "#008270")
            .style("opacity", "0.7")
            .attr("r", r)
            .attr("cx", r)
            .attr("cy", r);
        g.append("text")
            .attr("text-anchor", "middle")
            .attr("fill", "#FFF")            
            .attr("transform", "translate(" + r + ", " + r + ")")
            .style("font-size", "17px")
            .style("line-height", "1.1em")
            .append("tspan")
               .text(labels.header)
               .attr("x", "0")
               .attr("dy", "-0.3em")
            .append("tspan")
               .text(labels.amount)
               .attr("x", "0")
               .attr("dy", "1em")
               .style("font-size", "34px");
	}

	
}