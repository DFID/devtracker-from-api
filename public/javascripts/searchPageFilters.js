/*
Global Variable Explanation:
window.searchType can accept the following parameters to identify the type of searching:
C -> country all projects page
F -> Free text search. This supports the top right search box and the mid search box located in the index file.
S -> Sector page search
R -> Region page search
O -> Other Govt Departments
*/

$(document).ready(function() {
    refreshPagination(window.project_count);
    var oipaLink = '';

    // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
    // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
    // $('.search-result h3 a small').hasClass('GB-*').show();
    var budgetLowerBound = parseInt($('#budget_lower_bound').val()) > 0 ? $('#budget_lower_bound').val() : '';
    var budgetHigherBound = parseInt($('#budget_higher_bound').val()) > 0 ? $('#budget_higher_bound').val() : '';
    var currencyLink = '/currency';
    switch (window.searchType){
        case 'C':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_country='+window.CountryCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'F':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&reporting_organisation_startswith=GB'+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'S':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'R':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_region='+window.RegionCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'O':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation='+window.ogd_code+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
    }
    function refreshOipaLink(searchType,trigger){
        if (trigger == 0){
            budgetLowerBound = $('#budget_lower_bound').val() > 0 ? $('#budget_lower_bound').val() : '';
            budgetHigherBound = $('#budget_higher_bound').val() > 0 ? $('#budget_higher_bound').val() : '';
        }
        switch (window.searchType){
            case 'C':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_country='+window.CountryCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'F':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&reporting_organisation_startswith=GB'+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'S':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'R':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation=GB-GOV-1&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_recipient_region='+window.RegionCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'O':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation='+window.ogd_code+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('#sort_results_type').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        }
    };
    var returnedProjectCount = 0;

    /*The following click functions are to trigger the filters and orders*/
    $('#sortProjTitle').on('click',function(e){
        if($(this).text()=="▼")
        {
            $('#sort_results_type').val('title');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▲');
        }
        else
        {
            $('#sort_results_type').val('-title');
            refreshOipaLink(window.searchType,0);
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
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $(this).text('▲');
        }
        else
        {
            $('#sort_results_type').val('-activity_plus_child_budget_value');
            refreshOipaLink(window.searchType,0);
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
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });
    
    $('.document_type').click(function(){
        var tmpDocumentTypeList = $('.document_type:checked').map(function(){return $(this).val()}).get().join();
        $('#selected_document_type').val(tmpDocumentTypeList);
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });

    $('.implementingOrg_type').click(function(){
        var tmpDocumentTypeList = $('.implementingOrg_type:checked').map(function(){return $(this).val()}).get().join();
        $('#selected_implementingOrg_type').val(tmpDocumentTypeList);
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });

    $('.sector').click(function(){
        var tmpSectorList = $('.sector:checked').map(function(){return $(this).val()}).get().join();
        $('#selected_sectors').val(tmpSectorList);
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });

    //The following updates the result based on selected location country filter
    $('.location_country').click(function(){
        var tmpCountryList = $('.location_country:checked').map(function(){return $(this).val()}).get().join();
        $('#locationCountryFilterStates').val(tmpCountryList);
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });

    //The following updates the result based on selected location region filter
    $('.location_region').click(function(){
        var tmpRegionList = $('.location_region:checked').map(function(){return $(this).val()}).get().join();
        $('#locationRegionFilterStates').val(tmpRegionList);
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });

    //<input style="color: black; width: 40%; font-size: 0.8em;" value="£0"> - <input value="£417,999,994" style="color: black; width: 40%; font-size: 0.8em;">

    $("#slider-vertical").slider({
        orientation: "horizontal",
        range: true,
        min: 0,
        max: window.maxBudget,
        step : (Math.round(window.maxBudget / 100) * 100)/100,
        values: [0,window.maxBudget],
        slide: function( event, ui ) {
            //$( "#amount" ).html( "£" + addCommas(ui.values[0]) + " - £" + addCommas(ui.values[1]) );
            //$( "#amount" ).html('<input id="budget_slider_start" style="color: black; width: 40%; font-size: 0.8em;" value="£'+addCommas(ui.values[0])+'"> - <input id="budget_slider_end" value="£'+addCommas(ui.values[1])+'" style="color: black; width: 40%; font-size: 0.8em;">');
            $('#budget_slider_start').val(addCommas('£'+ui.values[0]));
            $('#budget_slider_end').val(addCommas('£'+ui.values[1]));
        },
        change: function(event, ui){
            $('#budget_lower_bound').val(ui.values[0]);
            $('#budget_higher_bound').val(ui.values[1]);
            refreshOipaLink(window.searchType,0);
            generateProjectListAjax(oipaLink);
        }
    });
    //$( "#amount" ).html( "£" + addCommas($( "#slider-vertical" ).slider( "values", 0 )) + " - £" + addCommas($( "#slider-vertical" ).slider( "values", 1 )) );
    $( "#amount" ).html('<input id="budget_slider_start" style="color: black; width: 40%; font-size: 0.8em;" value="£'+addCommas($( "#slider-vertical" ).slider( "values", 0 ))+'"> - <input id="budget_slider_end" value="£'+addCommas($( "#slider-vertical" ).slider( "values", 1 ))+'" style="color: black; width: 40%; font-size: 0.8em;"><button id="budget_slider_update" style="font-size: 0.8em; padding: 0px; margin: 0px; width: 13%; height: 25px;">Go</button>');
    $('#date-range').html('<input id="date_slider_start" style="color: black; width: 40%; font-size: 0.8em;" value=""> - <input id="date_slider_end" value="" style="color: black; width: 40%; font-size: 0.8em;"><button id="date_slider_update" style="font-size: 0.8em; padding: 0px; margin: 0px; width: 13%; height: 25px;">Go</button>');
    
    $('#budget_higher_bound').val($( "#slider-vertical" ).slider( "values", 1 ));
    
    $('#budget_slider_update').click(function(){
        $('#budget_lower_bound').val($('#budget_slider_start').val().trim().replace(/[^0-9]/g,""));
        $('#budget_higher_bound').val($('#budget_slider_end').val().trim().replace(/[^0-9]/g,""));
        budgetHigherBound = $('#budget_higher_bound').val();
        budgetLowerBound = $('#budget_lower_bound').val();
        refreshOipaLink(window.searchType,1);
        console.log('link: '+oipaLink);
        generateProjectListAjax(oipaLink);
    });

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
        //$('#date-range').html(tempStartDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + tempEndDt.customFormat("#DD# #MMM# #YYYY#"));
        $('#date_slider_start').val(tempStartDt.customFormat("#DD# #MMM# #YYYY#"));
        $('#date_slider_end').val(tempEndDt.customFormat("#DD# #MMM# #YYYY#"));
        },
        change: function(event, ui){
            $('#date-slider-disclaimer').show();
            var tempStartDt = new Date(ui.values[0]);
            var tempEndDt = new Date(ui.values[1]);
            $('#date_lower_bound').val(tempStartDt.customFormat("#YYYY#-#MM#-#DD#"));
            $('#date_higher_bound').val(tempEndDt.customFormat("#YYYY#-#MM#-#DD#"));
            refreshOipaLink(window.searchType,0);
            generateProjectListAjax(oipaLink);
        }
        /*change: function(event, ui){
        //TO DO
        }*/
    });
    //$('#date-range').html(StartDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + EndDt.customFormat("#DD# #MMM# #YYYY#"));
    $('#date_slider_start').datepicker({
        changeMonth: true,
        changeYear: true
    });
    $('#date_slider_end').datepicker({
        changeMonth: true,
        changeYear: true
    });
    //$('#date_slider_start').datepicker("option","dateFormat","yy-mm-dd");
    $('#date_slider_start').datepicker("option","dateFormat","dd M yy");
    $('#date_slider_end').datepicker("option","dateFormat","dd M yy");
    $('#date_slider_start').val(StartDt.customFormat("#DD# #MMM# #YYYY#"));
    $('#date_slider_end').val(EndDt.customFormat("#DD# #MMM# #YYYY#"));
    $('#date_slider_update').click(function(){
        $('#date-slider-disclaimer').show();
        var tempStartDate = new Date($('#date_slider_start').val());
        var tempEndDate = new Date($('#date_slider_end').val());
        $('#date_lower_bound').val(tempStartDate.customFormat("#YYYY#-#MM#-#DD#"));
        $('#date_higher_bound').val(tempEndDate.customFormat("#YYYY#-#MM#-#DD#"));
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink);
    });
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
                    $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0.5em 0.7em 0em;"><p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>Default filter shows currently active projects. To see projects at other stages, use the status filters.</p></div>');
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
                        validResults['total_plus_child_budget_currency'] = !isEmpty(result.aggregations.activity_children.budget_currency) ? result.aggregations.activity_children.budget_currency : !isEmpty(result.aggregations.activity_children.incoming_funds_currency)? result.aggregations.activity_children.incoming_funds_currency: !isEmpty(result.aggregations.activity_children.expenditure_currency)? result.aggregations.activity_children.expenditure_currency: !isEmpty(result.aggregations.activity_children.disbursement_currency)? result.aggregations.activity_children.disbursement_currency: !isEmpty(result.aggregations.activity_children.commitment_currency)? result.aggregations.activity_children.commitment_currency: "GBP";
                        validResults['total_plus_child_budget_currency_value'] = '';
                        //$.getJSON(currencyLink,{amount: validResults['total_plus_child_budget_value'], currency: validResults['total_plus_child_budget_currency']}).done(function(json){validResults['total_plus_child_budget_currency_value'] = json.output});
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
                        //var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+addCommas(validResults['total_plus_child_budget_value'],'B')+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+validResults['total_plus_child_budget_value']+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        $('#showResults').append(tempString);
                    });
                    generateBudgetValues();
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

    function generateBudgetValues(){
        $('.tpcbcv').each(function(){
            var temp_amount = $(this).children('.total_plus_child_budget_currency_value_amount').text();
            var temp_currency = $(this).children('.total_plus_child_budget_currency_value_cur').text();
            var temp_response = '';
            $.ajax({
                method: "GET",
                async: false,
                url: "/currency",
                data: {amount: temp_amount, currency: temp_currency},
            }).done(function(msg){
                //console.log("saved: " + msg.output);
                temp_response = msg.output;
            });
            $(this).before(temp_response);
        });
    }

    /*generateProjectListAjax function re-populates the project list based on the new api call when clicked on a filter or order*/

    function generateProjectListAjax(oipaLink){
        $.getJSON(oipaLink,{
            format: "json",
            async: false,
        })
        .done(function(json){
            $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0.5em 0.7em 0em;"><p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>Default filter shows currently active projects. To see projects at other stages, use the status filters.</p></div>');
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
                validResults['total_plus_child_budget_currency'] = !isEmpty(result.aggregations.activity_children.budget_currency) ? result.aggregations.activity_children.budget_currency : !isEmpty(result.aggregations.activity_children.incoming_funds_currency)? result.aggregations.activity_children.incoming_funds_currency: !isEmpty(result.aggregations.activity_children.expenditure_currency)? result.aggregations.activity_children.expenditure_currency: !isEmpty(result.aggregations.activity_children.disbursement_currency)? result.aggregations.activity_children.disbursement_currency: !isEmpty(result.aggregations.activity_children.commitment_currency)? result.aggregations.activity_children.commitment_currency: "GBP";
                validResults['total_plus_child_budget_currency_value'] = '';
                //$.getJSON(currencyLink,{amount: validResults['total_plus_child_budget_value'], currency: validResults['total_plus_child_budget_currency']}).done(function(json){validResults['total_plus_child_budget_currency_value'] = json.output});
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
                //var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+addCommas(validResults['total_plus_child_budget_value'],'B')+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                //var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+validResults['total_plus_child_budget_currency_value']+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['id']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+validResults['total_plus_child_budget_value']+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                $('#showResults').append(tempString);
            });
            // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
            // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
            generateBudgetValues();
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
    
         /*if($(this).text() == '+'){
            $(this).text('-');
            $(this).parent().find("div[name=countries]").show();
            $(this).parent().find("div[name=regions]").show();
            $(this).parent().find("ul").show();
            $(this).parent().find(".mContent").show();
         }
         else{
            $(this).text('+');
            $(this).parent().find("div[name=countries]").hide();
            $(this).parent().find("div[name=regions]").hide();
            $(this).parent().find("ul").hide();
            $(this).parent().find(".mContent").hide();
         }*/

         if($(this).hasClass('proj-filter-exp-collapse-sign-down')){
            $(this).removeClass('proj-filter-exp-collapse-sign-down').addClass('proj-filter-exp-collapse-sign-up');
            //$(this).text('-');
            $(this).parent().find("div[name=countries]").show();
            $(this).parent().find("div[name=regions]").show();
            $(this).parent().find("ul").show();
            $(this).parent().find(".mContent").show();
         }
         else{
            $(this).removeClass('proj-filter-exp-collapse-sign-up').addClass('proj-filter-exp-collapse-sign-down');
            //$(this).text('+');
            $(this).parent().find("div[name=countries]").hide();
            $(this).parent().find("div[name=regions]").hide();
            $(this).parent().find("ul").hide();
            $(this).parent().find(".mContent").hide();
         }
       });
    
       $('.proj-filter-exp-collapse-text').click(function(){
    
          $(this).parent().find('.proj-filter-exp-collapse-sign').each(function(){
    
             /*if($(this).text() == '+'){
                 $(this).text('-');
                 $(this).parent().find("div[name=countries]").show('slow');
                 $(this).parent().find("div[name=regions]").show('slow');
                 $(this).parent().find("ul").show('slow');
                 $(this).parent().find(".mContent").show('slow');
              }
              else{
                 $(this).text('+');
                 $(this).parent().find("div[name=countries]").hide('slow');
                 $(this).parent().find("div[name=regions]").hide('slow');
                 $(this).parent().find("ul").hide('slow');
                 $(this).parent().find(".mContent").hide('slow');
              }*/

            if($(this).hasClass('proj-filter-exp-collapse-sign-down')){
                $(this).removeClass('proj-filter-exp-collapse-sign-down').addClass('proj-filter-exp-collapse-sign-up');
                //$(this).text('-');
                $(this).parent().find("div[name=countries]").show();
                $(this).parent().find("div[name=regions]").show();
                $(this).parent().find("ul").show();
                $(this).parent().find(".mContent").show();
             }
             else{
                $(this).removeClass('proj-filter-exp-collapse-sign-up').addClass('proj-filter-exp-collapse-sign-down');
                //$(this).text('+');
                $(this).parent().find("div[name=countries]").hide();
                $(this).parent().find("div[name=regions]").hide();
                $(this).parent().find("ul").hide();
                $(this).parent().find(".mContent").hide();
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