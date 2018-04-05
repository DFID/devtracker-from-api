(function($, undefined){

    // test to detect if SVG and therefore D3 is supported
    var supportsSvg = !!document.createElementNS && !!document.createElementNS('http://www.w3.org/2000/svg', 'svg').createSVGRect;
    
    if(supportsSvg) {

        // extract the embedded data out of the budget by year chart
        var data = $('#budget-year-chart .data-table tbody tr').map(function(){
            var row = $(this);
            // we return an embedded array because map appears to flatten
            // the results otherwise
            return [[
                row.find('td:first').data('year'),
                parseInt(row.find('td:last').data('value'))
            ]];
        }).get();

        // finally we prepend the header details for the chart
        data.unshift(["Year", "Budget"]);

        // clear out the data table and draw the graph
        $('#budget-year-chart').empty();
        charts.bar("#budget-year-chart", data, ".2s", null, null, ["#D8DCBF"]);
    }
})(jQuery)