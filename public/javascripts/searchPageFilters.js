/*
Global Variable Explanation:
window.searchType can accept the following parameters to identify the type of searching:
C -> country all projects page
F -> Free text search. This supports the top right search box and the mid search box located in the index file.
S -> Sector page search
R -> Region page search
*/

$(document).ready(function() {
    refreshPagination(window.project_count);
    var oipaLink = '';
    switch (window.searchType){
        case 'C':
            break;
        case 'F':
            oipaLink = window.oipaApiUrl + 'activities?hierarchy=1&page_size=10&format=json&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations,description&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_child_budget_value_gte='+$('#budget_lower_bound').val()+'&total_child_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val();
            break;
        case 'S':
            break;
        case 'R':
            break;
    }
    function refreshOipaLink(searchType){
        switch (window.searchType){
            case 'C':
                break;
            case 'F':
                oipaLink = window.oipaApiUrl + 'activities?hierarchy=1&page_size=10&format=json&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations,description&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_child_budget_value_gte='+$('#budget_lower_bound').val()+'&total_child_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val();
                break;
            case 'S':
                break;
            case 'R':
                break;
        }
    };
    var returnedProjectCount = 0;

    /*The following click functions are to trigger the filters and orders*/
    $('#sortProjTitle').on('click',function(e){
        if($(this).text()=="▼")
        {
            $('#sort_results_type').val('title');
            refreshOipaLink(window.searchType);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▲');
        }
        else
        {
            $('#sort_results_type').val('-title');
            refreshOipaLink(window.searchType);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▼');
        }

        setDefaultBorder();
        $(this).css('border', "solid 1px #FFA500");
        e.preventDefault();
    });

    $('#sortProjBudg').click(function(e){
        if($(this).text()=="▼")
        {
            $('#sort_results_type').val('total_child_budget_value');
            refreshOipaLink(window.searchType);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▲');
        }
        else
        {
            $('#sort_results_type').val('-total_child_budget_value');
            refreshOipaLink(window.searchType);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▼');
        }

        setDefaultBorder();
        $(this).css('border', "solid 1px #FFA500");
        e.preventDefault();
    });

    $('.activity_status').click(function(){
        var tmpStatusList = $('.activity_status:checked').map(function(){return $(this).val()}).get().join();
        if(tmpStatusList.length > 0){
            $('#activity_status_states').val(tmpStatusList);
        }
        else{
            $('#activity_status_states').val('1,2,3,4,5');
        }
        refreshOipaLink(window.searchType);
        generateProjectListAjax(oipaLink);
    });
    
    $('.sector').click(function(){
        var tmpSectorList = $('.sector:checked').map(function(){return $(this).val()}).get().join();
        $('#selected_sectors').val(tmpSectorList);
        //refreshOipaLink(window.searchType);
        //generateProjectListAjax(oipaLink);
    });

    $("#slider-vertical").slider({
        orientation: "horizontal",
        range: true,
        min: 0,
        max: window.maxBudget,
        step : (Math.round(window.maxBudget / 100) * 100)/100,
        values: [0,window.maxBudget],
        slide: function( event, ui ) {
            $( "#amount" ).html( "£" + addCommas(ui.values[0]) + " - £" + addCommas(ui.values[1]) );
        },
        change: function(event, ui){
            $('#budget_lower_bound').val(ui.values[0]);
            $('#budget_higher_bound').val(ui.values[1]);
            refreshOipaLink(window.searchType);
            generateProjectListAjax(oipaLink);
        }
    });
    $( "#amount" ).html( "£" + addCommas($( "#slider-vertical" ).slider( "values", 0 )) + " - £" + addCommas($( "#slider-vertical" ).slider( "values", 1 )) );
    function setDefaultBorder(){
        $(".sort-proj-sectors").each(function(){
            $(this).css('border', "none");
        });
    }


    StartDt = new Date (window.StartDate.slice(0,10));
    EndDt = new Date (window.EndDate.slice(0,10));
    $("#date-slider-vertical").slider({
        orientation: "horizontal",
        range:true,
        min: Date.parse(StartDt),
        max: Date.parse(EndDt),
        step: 86400000,
        values: [Date.parse(StartDt), Date.parse(EndDt)],
        slide: function(event, ui){
            var tempStartDt = new Date(ui.values[0]);
            var tempEndDt = new Date(ui.values[1]);
        $('#date-range').html(tempStartDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + tempEndDt.customFormat("#DD# #MMM# #YYYY#"));
        },
        change: function(event, ui){
            var tempStartDt = new Date(ui.values[0]);
            var tempEndDt = new Date(ui.values[1]);
            $('#date_lower_bound').val(tempStartDt.customFormat("#YYYY#-#MM#-#DD#"));
            $('#date_higher_bound').val(tempEndDt.customFormat("#YYYY#-#MM#-#DD#"));
            refreshOipaLink(window.searchType);
            generateProjectListAjax(oipaLink);
        }
        /*change: function(event, ui){
        //TO DO
        }*/
    });
    $('#date-range').html(StartDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + EndDt.customFormat("#DD# #MMM# #YYYY#"));
    /*refreshPagination function reloads the pagination information to accommodate with the updated api call*/
    function refreshPagination(projectCount){
        $('#light-pagination').pagination({
            items: projectCount,
            itemsOnPage: 10,
            cssStyle: 'compact-theme',
            onPageClick: function(pageNumber,event){
                pagedOipaLink = oipaLink + '&page='+ pageNumber;
                $.getJSON(pagedOipaLink,{
                    format: "json"
                }).done(function(json){
                    $('#showResults').html("");
                    if (!isEmpty(json.next)){
                        var tmpStr = '<div>Now showing projects <span name="afterFilteringAmount" style="display:inline;"></span><span id="numberofResults" value="" style="display:inline;">'+(1+(10*(pageNumber-1)))+' - '+(10*pageNumber)+'</span> of '+projectCount+'</div>';
                        $('#showResults').append(tmpStr);
                    }
                    else{
                        var tmpStr = '<div>Now showing projects '+(1+(10*(pageNumber-1)))+' - '+projectCount+' of '+projectCount+'</div>';
                        $('#showResults').append(tmpStr);
                    }
                    $.each(json.results,function(i,result){
                        var validResults = {};
                        validResults['iati_identifier'] = !isEmpty(result.iati_identifier) ? result.iati_identifier : "";
                        validResults['title'] = !isEmpty(result.title.narratives[0]) ? result.title.narratives[0].text : "";
                        validResults['total_child_budget_value'] = !isEmpty(result.activity_aggregations.total_child_budget_value) ? result.activity_aggregations.total_child_budget_value : 0;
                        validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                        validResults['reporting_organisations'] = !isEmpty(result.reporting_organisations[0].narratives[0]) ? result.reporting_organisations[0].narratives[0].text : "";
                        validResults['description'] = !isEmpty(result.description[0].narratives[0]) ? result.description[0].narratives[0].text : "";
                        var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> £'+addCommas(validResults['total_child_budget_value'])+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        $('#showResults').append(tempString);
                    });
                })
                .fail(function(error){
                    $('#showResults').text(error.toSource());
                    console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
                });
            }
        });
    };

    /*generateProjectListAjax function re-populates the project list based on the new api call when clicked on a filter or order*/

    function generateProjectListAjax(oipaLink){
        $.getJSON(oipaLink,{
            format: "json"
        })
        .done(function(json){
            $('#showResults').html("");
            returnedProjectCount = json.count;
            refreshPagination(json.count);
            if (!isEmpty(json.next)){
                var tmpStr = '<div>Now showing projects <span name="afterFilteringAmount" style="display:inline;"></span><span id="numberofResults" value="" style="display:inline;">1 - 10</span> of '+returnedProjectCount+'</div>';
                $('#showResults').append(tmpStr);
            }
            else{
                var tmpStr = '<div>Now showing projects '+returnedProjectCount+' of '+returnedProjectCount+'</div>';
                $('#showResults').append(tmpStr);
            }
            $.each(json.results,function(i,result){
                var validResults = {};
                validResults['iati_identifier'] = !isEmpty(result.iati_identifier) ? result.iati_identifier : "";
                validResults['title'] = !isEmpty(result.title.narratives[0]) ? result.title.narratives[0].text : "";
                validResults['total_child_budget_value'] = !isEmpty(result.activity_aggregations.total_child_budget_value) ? result.activity_aggregations.total_child_budget_value : 0;
                validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                validResults['reporting_organisations'] = !isEmpty(result.reporting_organisations[0].narratives[0]) ? result.reporting_organisations[0].narratives[0].text : "";
                validResults['description'] = !isEmpty(result.description[0].narratives[0]) ? result.description[0].narratives[0].text : "";
                var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> £'+addCommas(validResults['total_child_budget_value'])+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                $('#showResults').append(tempString);
            });
        })
        .fail(function(error){
            //$('#showResults').text(error.toSource());
            console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
        });
    }

    /*This method attaches the +/- sign to the relevant filter expansion label*/
    attachFilterExpColClickEvent();
    function attachFilterExpColClickEvent(){
       $('.proj-filter-exp-collapse-sign').click(function(){
    
         if($(this).text() == '+'){
            $(this).text('-');
            $(this).parent().find("div[name=countries]").show('slow');
            $(this).parent().find("div[name=regions]").show('slow');
            $(this).parent().find("ul").show('slow');
         }
         else{
            $(this).text('+');
            $(this).parent().find("div[name=countries]").hide('slow');
            $(this).parent().find("div[name=regions]").hide('slow');
            $(this).parent().find("ul").hide('slow');
         }
       });
    
       $('.proj-filter-exp-collapse-text').click(function(){
    
          $(this).parent().find('.proj-filter-exp-collapse-sign').each(function(){
    
             if($(this).text() == '+'){
                 $(this).text('-');
                 $(this).parent().find("div[name=countries]").show('slow');
                 $(this).parent().find("div[name=regions]").show('slow');
                 $(this).parent().find("ul").show('slow');
              }
              else{
                 $(this).text('+');
                 $(this).parent().find("div[name=countries]").hide('slow');
                 $(this).parent().find("div[name=regions]").hide('slow');
                 $(this).parent().find("ul").hide('slow');
              }
          });
       });
    }

    /*addCommas function is used to properly separate */
    function addCommas(num) {   
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }
    $( document ).ajaxStart(function() {
        $('.modal').show();
    });
    $( document ).ajaxStop(function() {
        $('.modal').hide();
    });
    function isEmpty(val){
        return (val === undefined || val == null || val.length <= 0) ? true : false;
    }
});