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
    // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
    // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
    // $('.search-result h3 a small').hasClass('GB-*').show();
    switch (window.searchType){
        case 'C':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_country='+window.CountryCode;
            break;
        case 'F':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&reporting_organisation_startswith=GB';
            break;
        case 'S':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val();
            break;
        case 'R':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_region='+window.RegionCode;
            break;
    }
    function refreshOipaLink(searchType){
        switch (window.searchType){
            case 'C':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_country='+window.CountryCode;
                break;
            case 'F':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&reporting_organisation_startswith=GB';
                break;
            case 'S':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val();
                break;
            case 'R':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&activity_plus_child_aggregation_budget_value_gte='+$('#budget_lower_bound').val()+'&activity_plus_child_aggregation_budget_value_lte='+$('#budget_higher_bound').val()+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_region='+window.RegionCode;
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
            $('#sort_results_type').val('activity_plus_child_budget_value');
            refreshOipaLink(window.searchType);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▲');
        }
        else
        {
            $('#sort_results_type').val('-activity_plus_child_budget_value');
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
        refreshOipaLink(window.searchType);
        generateProjectListAjax(oipaLink);
    });

    //The following updates the result based on selected location country filter
    $('.location_country').click(function(){
        var tmpCountryList = $('.location_country:checked').map(function(){return $(this).val()}).get().join();
        $('#locationCountryFilterStates').val(tmpCountryList);
        refreshOipaLink(window.searchType);
        generateProjectListAjax(oipaLink);
    });

    //The following updates the result based on selected location region filter
    $('.location_region').click(function(){
        var tmpRegionList = $('.location_region:checked').map(function(){return $(this).val()}).get().join();
        $('#locationRegionFilterStates').val(tmpRegionList);
        refreshOipaLink(window.searchType);
        generateProjectListAjax(oipaLink);
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
                        //Check title
                        if(!isEmpty(result.title.narratives)){
                            if(!isEmpty(result.title.narratives[0].text)){
                                validResults['title'] = result.title.narratives[0].text;
                            }
                            else {
                                validResults['title'] = "";    
                            }
                        }
                        else{
                            validResults['title'] = "";
                        }
                        //validResults['title'] = !isEmpty(result.title.narratives[0]) ? result.title.narratives[0].text : "";
                        validResults['total_plus_child_budget_value'] = !isEmpty(result.aggregations.activity_children.budget_value) ? result.aggregations.activity_children.budget_value : 0;
                        validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                        //Check reporting organization
                        if(!isEmpty(result.reporting_organisations)){
                            if(!isEmpty(result.reporting_organisations[0].narratives)){
                                validResults['reporting_organisations'] = result.reporting_organisations[0].narratives[0].text;
                            }
                            else {
                                validResults['reporting_organisations'] = "";    
                            }
                        }
                        else{
                            validResults['reporting_organisations'] = "";
                        }
                        //validResults['reporting_organisations'] = !isEmpty(result.reporting_organisations[0].narratives[0]) ? result.reporting_organisations[0].narratives[0].text : "";
                        //check description's existence
                        if(!isEmpty(result.descriptions)){
                            if(!isEmpty(result.descriptions[0].narratives)){
                                validResults['description'] = result.descriptions[0].narratives[0].text;
                            }
                            else {
                                validResults['description'] = "";    
                            }
                        }
                        else{
                            validResults['description'] = "";
                        }
                        //validResults['description'] = !isEmpty(result.description[0].narratives[0]) ? result.description[0].narratives[0].text : "";
                        var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+addCommas(validResults['total_plus_child_budget_value'],'B')+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        $('#showResults').append(tempString);
                    });
                })
                .fail(function(error){
                    $('#showResults').text(error.toSource());
                    console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
                });
            }
        });
        // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
        // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
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
                /*var tmpStr = "";
                if(typeof window.searchQuery !== 'undefined'){
                    tmpStr = '<div class="search-result"><p style="padding-top:.33em">Your search - <em>'+window.searchQuery+'</em> - did not match any documents.  </p><p style="margin-top:1em">Suggestions:</p><ul style="margin:0 0 2em;margin-left:1.3em"><li>Make sure all words are spelled correctly.</li><li>Try different keywords.</li><li>Try more general keywords.</li><li>Try fewer keywords.</li></ul></div>';
                }
                else{
                    tmpStr = '<div>Now showing projects '+returnedProjectCount+' of '+returnedProjectCount+'</div>';
                }*/
                $('#showResults').append(tmpStr);
            }
            $.each(json.results,function(i,result){
                var validResults = {};
                validResults['iati_identifier'] = !isEmpty(result.iati_identifier) ? result.iati_identifier : "";
                validResults['id'] = !isEmpty(result.id) ? result.id : "";
                //Check title
                if(!isEmpty(result.title.narratives)){
                    if(!isEmpty(result.title.narratives[0].text)){
                        validResults['title'] = result.title.narratives[0].text;
                    }
                    else {
                        validResults['title'] = "";    
                    }
                }
                else{
                    validResults['title'] = "";
                }
                //validResults['title'] = !isEmpty(result.title.narratives[0]) ? result.title.narratives[0].text : "";
                validResults['total_plus_child_budget_value'] = !isEmpty(result.aggregations.activity_children.budget_value) ? result.aggregations.activity_children.budget_value : 0;
                validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                //Check reporting organization
                if(!isEmpty(result.reporting_organisations)){
                    if(!isEmpty(result.reporting_organisations[0].narratives)){
                        validResults['reporting_organisations'] = result.reporting_organisations[0].narratives[0].text;
                    }
                    else {
                        validResults['reporting_organisations'] = "";    
                    }
                }
                else{
                    validResults['reporting_organisations'] = "";
                }
                //validResults['reporting_organisations'] = !isEmpty(result.reporting_organisations[0].narratives[0]) ? result.reporting_organisations[0].narratives[0].text : "";
                //check description's existence
                if(!isEmpty(result.descriptions)){
                    if(!isEmpty(result.descriptions[0].narratives)){
                        validResults['description'] = result.descriptions[0].narratives[0].text;
                    }
                    else {
                        validResults['description'] = "";    
                    }
                }
                else{
                    validResults['description'] = "";
                }
                //validResults['description'] = !isEmpty(result.description[0].narratives[0]) ? result.description[0].narratives[0].text : "";
                var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+addCommas(validResults['total_plus_child_budget_value'],'B')+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                $('#showResults').append(tempString);
            });
            // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
            // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
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
    function addCommas(num,type) {
        switch (type){
            case 'B':
                if (parseInt(num) != 0) {
                    return '£' + num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
                }
                else{
                    return 'Not Provided';
                }
                break;
            default:
                return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }
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