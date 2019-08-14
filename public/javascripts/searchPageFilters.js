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
    var oipaLink2 = '';
    var all_reporting_orgs = window.reportingOrgs;
    // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
    // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
    // $('.search-result h3 a small').hasClass('GB-*').show();
    var budgetLowerBound = parseInt($('#budget_lower_bound').val()) > 0 ? $('#budget_lower_bound').val() : '';
    var budgetHigherBound = parseInt($('#budget_higher_bound').val()) > 0 ? $('#budget_higher_bound').val() : '';
    var currencyLink = '/currency';
    switch (window.searchType){
        case 'C':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&recipient_country='+window.CountryCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'F':
            //oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisations,activity_plus_child_aggregation,descriptions&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            oipaLink = '/getFTSResponse?searchQuery='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&budgetLowerBound='+budgetLowerBound+'&budgetHigherBound='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            console.log(oipaLink);
            break;
        case 'S':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'R':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&recipient_region='+window.RegionCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        case 'O':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.ogd_code+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
    }
    function refreshOipaLink(searchType,trigger){
        if (trigger == 0){
            budgetLowerBound = $('#budget_lower_bound').val() > 0 ? $('#budget_lower_bound').val() : '';
            budgetHigherBound = $('#budget_higher_bound').val() > 0 ? $('#budget_higher_bound').val() : '';
        }
        switch (window.searchType){
            case 'C':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&recipient_country='+window.CountryCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'F':
                oipaLink = '/getFTSResponse?searchQuery='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&budgetLowerBound='+budgetLowerBound+'&budgetHigherBound='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'S':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&related_activity_sector='+window.SectorCode + '&recipient_country=' + $('#locationCountryFilterStates').val() + '&recipient_region=' + $('#locationRegionFilterStates').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'R':
                oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&recipient_region='+window.RegionCode+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
                break;
            case 'O':
            oipaLink = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.ogd_code+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering='+$('.sort_results_type:first').val()+'&total_hierarchy_budget_gte='+budgetLowerBound+'&total_hierarchy_budget_lte='+budgetHigherBound+'&actual_start_date_gte='+$('#date_lower_bound').val()+'&planned_end_date_lte='+$('#date_higher_bound').val()+'&sector='+$('#selected_sectors').val()+'&document_link_category='+$('#selected_document_type').val() +'&participating_organisation='+$('#selected_implementingOrg_type').val();
            break;
        }
    };
    function refreshLHSButtons(){
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

        $('.reportingOrg_type').click(function(){
            var tmpDocumentTypeList = $('.reportingOrg_type:checked').map(function(){return $(this).val()}).get().join();
            $('#selected_reportingOrg_type').val(tmpDocumentTypeList);
            if($('#selected_reportingOrg_type').val().length == 0){
                window.reportingOrgs = all_reporting_orgs;
            }
            else{
                window.reportingOrgs = $('#selected_reportingOrg_type').val();
            }
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
            if (tmpCountryList.length == 0){
                //tmpCountryList = 'CM,GH,KE,LS,MW,MZ,NG,RW,SL,ZA,UG,TZ,ZM,IN,BD,PK,BS,DM,JM,VU,LK';
            }
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
        $("#slider-vertical").slider({
            orientation: "horizontal",
            range: true,
            min: 0,
            max: window.maxBudget,
            step : (Math.round(window.maxBudget / 100) * 100)/100,
            values: [0,window.maxBudget],
            slide: function( event, ui ) {
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
        $( "#amount" ).html('<input id="budget_slider_start" style="color: black; width: 35%; font-size: 0.8em;" value="£'+addCommas($( "#slider-vertical" ).slider( "values", 0 ))+'"> - <input id="budget_slider_end" value="£'+addCommas($( "#slider-vertical" ).slider( "values", 1 ))+'" style="color: black; width: 35%; font-size: 0.8em;"><button id="budget_slider_update" style="font-size: 0.8em; padding: 0px; margin: 0px 0px 0px 5px; width: 13%; height: 25px;">Go</button>');
        $('#date-range').html('<input id="date_slider_start" style="color: black; width: 35%; font-size: 0.8em;" value=""> - <input id="date_slider_end" value="" style="color: black; width: 35%; font-size: 0.8em;"><button id="date_slider_update" style="font-size: 0.8em; padding: 0px; margin: 0px 0px 0px 5px; width: 13%; height: 25px;">Go</button>');
        
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
        attachFilterExpColClickEvent();
    };
    //Methods for generating the LHS filters
    //Sector filter
    function populateSectorFilters(sectorList){
        if(sectorList.length > 0){
            $('#sector-filter').show();
            var tempSectors = '';
            $.each(sectorList,function(i,val){
                tempSectors = tempSectors + '<li><label for="activity_status_'+val[0]+'" title="'+val[0]+'"><input id="activity_status_'+val[0]+'" type="checkbox" value="'+val[1][0]+'" class="sector" name="sector">'+val[0]+'</label></li>';
            });
            tempSectors = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h3>Sectors</h3></span><div class="mContent"><ul style="display: block; margin: 5px;">' + tempSectors + '</ul></div><input type="hidden" id="selected_sectors" value=""  />';
            $('#sector-filter').html(tempSectors);
        }
        else{
            $('#sector-filter').hide();
        }
    }
    //Document type filter
    function populateDocumentTypeFilters(documentTypes){
        if(documentTypes.length > 0){
            //$('#document-filter').show();
            var tempDocuments = '';
            $.each(documentTypes,function(i,val){
                tempDocuments = tempDocuments + '<li><label for="document_type_'+val["document_link_category"]["code"]+'" title="'+val["document_link_category"]["name"]+'"><input id="document_type_'+val["document_link_category"]["code"]+'" type="checkbox" value="'+val["document_link_category"]["code"]+'" class="document_type" name="document_type">'+val["document_link_category"]["name"]+'</label></li>';
            });
            tempDocuments = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h3>Document Type</h3></span><div class="mContent"><ul style="display: block; margin: 5px;">' + tempDocuments + '</ul></div><input type="hidden" id="selected_document_type" value=""  />';
            $('#document-filter').html(tempDocuments);
        }
        else{
            $('#document-filter').hide();
        }
    }
    //Implementing org filters
    function populateImplOrgFilters(orgList){
        if(orgList.length > 0){
            $('#organisation-filter').show();
            var tempOrgs = '';
            $.each(orgList,function(i,val){
                tempOrgs = tempOrgs + '<li><label for="implementingOrg_type_'+val["participating_organisation_ref"]+'" title="'+val["participating_organisation"]+'"><input id="implementingOrg_type_'+val["participating_organisation_ref"]+'" type="checkbox" value="'+val["participating_organisation_ref"]+'" class="implementingOrg_type" name="implementingOrg_type">'+val["participating_organisation"]+'</label></li>';
            });
            tempOrgs = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h3>Organisations</h3></span><div class="mContent"><ul style="display: block; margin: 5px;">' + tempOrgs + '</ul></div><input type="hidden" id="selected_implementingOrg_type" value=""  />';
            $('#organisation-filter').html(tempOrgs);
        }
        else{
            $('#organisation-filter').hide();
        }
    }
    //Reporting org filters
    function populateReportingOrgFilters(orgList){
        if(orgList.length > 0){
            $('#reporting-organisation-filter').show();
            var tempOrgs = '';
            $.each(orgList,function(i,val){
                tempOrgs = tempOrgs + '<li><label for="reportingOrg_type_'+val["organisation_identifier"]+'" title="'+val["organisaion_name"]+'"><input id="reportingOrg_type_'+val["organisation_identifier"]+'" type="checkbox" value="'+val["organisation_identifier"]+'" class="reportingOrg_type" name="reportingOrg_type">'+val["organisaion_name"]+'</label></li>';
            });
            tempOrgs = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h3>Goverment Department</h3></span><div class="mContent"><ul style="display: block; margin: 5px;">' + tempOrgs + '</ul></div><input type="hidden" id="selected_reportingOrg_type" value=""  />';
            $('#reporting-organisation-filter').html(tempOrgs);
        }
        else{
            $('#reporting-organisation-filter').hide();
        }
    }
    //Populating country location filters
    function populateLocCountryFilters(countryList){
        if(countryList.length > 0){
            $('#sector-country-filter').show();
            var tempCountryLocations = '';
            $.each(countryList,function(i, val){
                tempCountryLocations = tempCountryLocations + '<li><label for="location_country_'+val['recipient_country']['code']+'" title="'+val['recipient_country']['name']+'"><input id="location_country_'+val['recipient_country']['code']+'" type="checkbox" value="'+val['recipient_country']['code']+'" class="location_country" name="locationCountry">'+val['recipient_country']['name']+'</label></li>';
            });
            tempCountryLocations = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h4>Countries</h4></span><div class="mContent"><ul style="display: block;margin: 5px;">' + tempCountryLocations + '</ul></div><input type="hidden" id="locationCountryFilterStates" value=""  />';
            $('#sector-country-filter').html(tempCountryLocations);
        }
        else{
            $('#sector-country-filter').hide();
        }
    }
    //Populating region location filters
    function populateLocRegionFilters(regionList){
        if(regionList.length > 0){
            $('#sector-region-filter').show();
            var tempRegionLocations = '';
            $.each(regionList,function(i, val){
                tempRegionLocations = tempRegionLocations + '<li><label for="location_region_'+val['recipient_region']['code']+'" title="'+val['recipient_region']['name']+'"><input id="location_region_'+val['recipient_region']['code']+'" type="checkbox" value="'+ val['recipient_region']['code']+'" class="location_region" name="locationRegion">'+val['recipient_region']['name']+'</label></li>';
            });
            tempRegionLocations = '<div class="proj-filter-exp-collapse-sign proj-filter-exp-collapse-sign-up"></div><span class="proj-filter-exp-collapse-text" style="cursor:pointer"><h4>Regions</h4></span><div class="mContent"><ul style="display: block;margin: 5px;">' + tempRegionLocations + '</ul></div><input type="hidden" id="locationRegionFilterStates" value=""  />';
            $('#sector-region-filter').html(tempRegionLocations);
        }
        else{
            $('#sector-region-filter').hide();
        }
    }
    function refreshLHSFiltersv2(projectStatus){
        $('#sector-filter').html('Refreshing sector filter<input type="hidden" id="selected_sectors" value=""  />');
        //$('#document-filter').html('Refreshing document type filter<input type="hidden" id="selected_document_type" value=""  />');
        $('#organisation-filter').html('Refreshing organisation filter<input type="hidden" id="selected_implementingOrg_type" value=""  />');
        $('#reporting-organisation-filter').html('Refreshing Goverment Department filter<input type="hidden" id="selected_reportingOrg_type" value=""  />');
        $('#budget-slider-filter').html('Refreshing..');
        $('#date-slider-filter').html('Refreshing..');
        $('#sector-filter').show();
        //$('#document-filter').show();
        $('#organisation-filter').show();
        if(window.searchType != 'S'){
            var apiType = window.searchType;
            var apiParams = '';
            var projectStatus = projectStatus;
            //Prepare the API call parameters
            if(window.searchType == 'C')
                apiParams = window.CountryCode;
            else if (window.searchType == 'F')
                apiParams = window.searchQuery;
            else if (window.searchType == 'R')
                apiParams = window.RegionCode;
            else
                apiParams = window.ogd_code;
            //Prepare the API parameters in one single string
            var apiParamsString = 'apiType='+apiType+'&apiParams='+apiParams+'&projectStatus='+projectStatus;
            // Start making the parallel api calls
            $.when($.getJSON('/getBudgetHi?'+apiParamsString),$.getJSON('/getHiLvlSectorList?'+apiParamsString),$.getJSON('/getStartDate?'+apiParamsString),$.getJSON('/getEndDate?'+apiParamsString),$.getJSON('/getDocumentTypeList?'+apiParamsString),$.getJSON('/getImplOrgList?'+apiParamsString), $.getJSON('/getReportingOrgList?'+apiParamsString))
            .done(function(projectnBudgetData,sectorData,startDate,endDate,documentTypeList,implOrgList,reportingOrgList){
                window.maxBudget = projectnBudgetData[0].output;
                window.StartDate = startDate[0].output;
                window.EndDate = endDate[0].output;
                //Populating sector filter
                populateSectorFilters(sectorData[0].output);
                //populating dcoument types filter
                //populateDocumentTypeFilters(documentTypeList[0].output);
                //implementing org filters
                populateImplOrgFilters(implOrgList[0].output);
                //reporting org filters
                console.log(reportingOrgList[0])
                populateReportingOrgFilters(reportingOrgList[0].output);
                //Budget and date sliders
                $('#budget-slider-filter').html('<div name="budget" style="margin-bottom: 10px"><h3>Budget Value</h3><input type="hidden" id="budget_lower_bound" value="0"  /><input type="hidden" id="budget_higher_bound" value=""  /></div><span id="amount" style="border: 0; font-weight: bold"></span><div id="slider-vertical" style="height: 13px;width : 80%; margin-top: 10px"></div>');
                $('#date-slider-filter').html('<div name="date" style="margin-top: 20px; margin-bottom: 10px;"><h3>Start and end date</h3><input type="hidden" id="date_lower_bound" value=""  /><input type="hidden" id="date_higher_bound" value=""  /></div><span id="date-range" style="border: 0; font-weight: bold;"></span><div id="date-slider-vertical" style="height: 13px;width : 80%; margin-top: 10px;"></div><div style="text-align: left; color: grey; margin-top: 15px; display: none" id="date-slider-disclaimer"><span style="margin-top: 4px; float: left; text-align: center; width: 186px;">Note: Projects without a valid end date have been removed from the filtered results.</span></div>');
                $('.activity_status').removeAttr('disabled');
                refreshLHSButtons();
            });
        }
        else if(window.searchType == 'S'){
            $('#sector-region-filter').html('Refreshing..<input type="hidden" id="locationRegionFilterStates" value=""  />');
            $('#sector-country-filter').html('Refreshing..<input type="hidden" id="locationCountryFilterStates" value=""  />');
            $('#sector-region-filter').show();
            $('#sector-country-filter').show();
            var apiType = window.searchType;
            var apiParams = window.SectorCode;
            var projectStatus = projectStatus;
            //Prepare the API parameters in one single string
            var apiParamsString = 'apiType='+apiType+'&apiParams='+apiParams+'&projectStatus='+projectStatus;
            // Start making the parallel api calls
            $.when($.getJSON('/getBudgetHi?'+apiParamsString),$.getJSON('/getHiLvlSectorList?'+apiParamsString),$.getJSON('/getStartDate?'+apiParamsString),$.getJSON('/getEndDate?'+apiParamsString),$.getJSON('/getDocumentTypeList?'+apiParamsString),$.getJSON('/getImplOrgList?'+apiParamsString),$.getJSON('/getSectorSpecificFilters?sectorCode='+apiParams+'&projectStatus='+projectStatus),$.getJSON('/getReportingOrgList?'+apiParamsString))
            .done(function(projectnBudgetData,sectorData,startDate,endDate,documentTypeList,implOrgList,sectorLocFilters,reportingOrgList){
                window.maxBudget = projectnBudgetData[0].output;
                window.StartDate = startDate[0].output;
                window.EndDate = endDate[0].output;
                //Populating country location filters
                populateLocCountryFilters(sectorLocFilters[0].output.LocationCountries);
                //Populating region location filters
                populateLocRegionFilters(sectorLocFilters[0].output.LocationRegions);
                //Populating sector filter
                populateSectorFilters(sectorData[0].output);
                //populating dcoument types filter
                populateDocumentTypeFilters(documentTypeList[0].output);
                //implementing org filters
                populateImplOrgFilters(implOrgList[0].output);
                //reporting org filters
                populateReportingOrgFilters(reportingOrgList[0].output);
                //Budget and date sliders
                $('#budget-slider-filter').html('<div name="budget" style="margin-bottom: 10px"><h3>Budget Value</h3><input type="hidden" id="budget_lower_bound" value="0"  /><input type="hidden" id="budget_higher_bound" value=""  /></div><span id="amount" style="border: 0; font-weight: bold"></span><div id="slider-vertical" style="height: 13px;width : 80%; margin-top: 10px"></div>');
                $('#date-slider-filter').html('<div name="date" style="margin-top: 20px; margin-bottom: 10px;"><h3>Start and end date</h3><input type="hidden" id="date_lower_bound" value=""  /><input type="hidden" id="date_higher_bound" value=""  /></div><span id="date-range" style="border: 0; font-weight: bold;"></span><div id="date-slider-vertical" style="height: 13px;width : 80%; margin-top: 10px;"></div><div style="text-align: left; color: grey; margin-top: 15px; display: none" id="date-slider-disclaimer"><span style="margin-top: 4px; float: left; text-align: center; width: 186px;">Note: Projects without a valid end date have been removed from the filtered results.</span></div>');
                $('.activity_status').removeAttr('disabled');
                refreshLHSButtons();
            });
        }
    };
    var returnedProjectCount = 0;

    /*The following click functions are to trigger the filters and orders*/
    $('.sortProjTitle').on('click',function(e){
        if($(this).text()=="▼")
        {
            $('.sort_results_type').val('title');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjTitle').text('▲');
        }
        else
        {
            $('.sort_results_type').val('-title');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjTitle').text('▼');
        }
        setDefaultBorder();
        $(this).css('border', "solid 1px #FFA500");
        e.preventDefault();
    });

    $('.sortProjSDate').on('click',function(e){
        if($(this).text()=="▼")
        {
            $('.sort_results_type').val('start_date');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjSDate').text('▲');
        }
        else
        {
            $('.sort_results_type').val('-start_date');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjSDate').text('▼');
        }
        setDefaultBorder();
        $(this).css('border', "solid 1px #FFA500");
        e.preventDefault();
    });

    $('.sortProjBudg').click(function(e){
        if($(this).text()=="▼")
        {
            $('.sort_results_type').val('activity_plus_child_budget_value');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjBudg').text('▲');
        }
        else
        {
            $('.sort_results_type').val('-activity_plus_child_budget_value');
            refreshOipaLink(window.searchType,0);
            //refreshPagination(returnedProjectCount);
            generateProjectListAjax(oipaLink);
            $('.sortProjBudg').text('▼');
        }

        setDefaultBorder();
        $(this).css('border', "solid 1px #FFA500");
        e.preventDefault();
    });

    $('.activity_status').click(function(){
        $('.activity_status').attr('disabled','disabled');
        var tmpStatusList = $('.activity_status:checked').map(function(){return $(this).val()}).get().join();
        if(tmpStatusList.length > 0){
            $('#activity_status_states').val(tmpStatusList);
        }
        else{
            $('#activity_status_states').val('1,2,3,4,5');
        }
        switch (window.searchType){
        case 'C':
            oipaLink2 = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering=-activity_plus_child_budget_value&total_hierarchy_budget_gte=&total_hierarchy_budget_lte=&actual_start_date_gte=&planned_end_date_lte=&sector=&recipient_country='+window.CountryCode+'&document_link_category=&participating_organisation=';
            break;
        case 'F':
            oipaLink2 = '/getFTSResponse?searchQuery='+window.searchQuery+'&activity_status='+$('#activity_status_states').val()+'&ordering=-activity_plus_child_budget_value&budgetLowerBound=&budgetHigherBound=&actual_start_date_gte=&planned_end_date_lte=&sector=&document_link_category=&participating_organisation=';
            break;
        case 'S':
            oipaLink2 = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering=-activity_plus_child_budget_value&total_hierarchy_budget_gte=&total_hierarchy_budget_lte=&actual_start_date_gte=&planned_end_date_lte=&sector=&related_activity_sector='+window.SectorCode + '&recipient_country=&recipient_region=&document_link_category=&participating_organisation=';
            break;
        case 'R':
            oipaLink2 = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.reportingOrgs+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering=-activity_plus_child_budget_value&total_hierarchy_budget_gte=&total_hierarchy_budget_lte=&actual_start_date_gte=&planned_end_date_lte=&sector=&recipient_region=&document_link_category=&participating_organisation=';
            break;
        case 'O':
            oipaLink2 = window.oipaApiUrl + 'activities/?hierarchy=1&page_size=10&format=json&reporting_organisation_identifier='+window.ogd_code+'&fields=aggregations,activity_status,id,iati_identifier,url,title,reporting_organisation,activity_plus_child_aggregation,descriptions&activity_status='+$('#activity_status_states').val()+'&ordering=-activity_plus_child_budget_value&total_hierarchy_budget_gte=&total_hierarchy_budget_lte=&actual_start_date_gte=&planned_end_date_lte=&sector=&document_link_category=&participating_organisation=';
            break;
    }
        refreshOipaLink(window.searchType,0);
        generateProjectListAjax(oipaLink2);
        refreshLHSFiltersv2($('#activity_status_states').val());
    });
    function setDefaultBorder(){
        $(".sort-proj-sectors").each(function(){
            $(this).css('border', "none");
        });
    };
    refreshLHSButtons();
    attachFilterExpColClickEvent();

    /*refreshPagination function reloads the pagination information to accommodate with the updated api call*/
    function refreshPagination(projectCount){
        $('.light-pagination').pagination({
            items: projectCount,
            itemsOnPage: 10,
            cssStyle: 'compact-theme',
            onPageClick: function(pageNumber,event){
                pagedOipaLink = oipaLink + '&page='+ pageNumber;
                //$('.modal').show();
                $('#showResults').animate({opacity: 0.4},500,function(){
                    $('.modal').show();
                });
                $.getJSON(pagedOipaLink,{
                    format: "json"
                }).done(function(json){
                    $('#showResults').animate({opacity: 1},500,function(){
                        $('.modal').hide();
                    });
                    if(window.searchType == 'F'){
                        $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 10px;">Default filter shows currently active projects. To see projects at other stages, either use the status filters or select the checkbox to search for completed projects.</div>');
                        json = json.output;
                    }
                    else{
                        $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 10px;">Default filter shows currently active projects. To see projects at other stages, use the status filters.</div>');
                    }
                    
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
                        console.log(validResults['iati_identifier'])
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
                        validResults['total_plus_child_budget_value'] = !isEmpty(result.activity_plus_child_aggregation.activity_children.budget_value) ? result.activity_plus_child_aggregation.activity_children.budget_value : 0;
                        validResults['total_plus_child_budget_currency'] = !isEmpty(result.activity_plus_child_aggregation.activity_children.budget_currency) ? result.activity_plus_child_aggregation.activity_children.budget_currency : !isEmpty(result.activity_plus_child_aggregation.activity_children.incoming_funds_currency)? result.activity_plus_child_aggregation.activity_children.incoming_funds_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.expenditure_currency)? result.activity_plus_child_aggregation.activity_children.expenditure_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.disbursement_currency)? result.activity_plus_child_aggregation.activity_children.disbursement_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.commitment_currency)? result.activity_plus_child_aggregation.activity_children.commitment_currency: "GBP";
                        validResults['total_plus_child_budget_currency_value'] = '';
                        //$.getJSON(currencyLink,{amount: validResults['total_plus_child_budget_value'], currency: validResults['total_plus_child_budget_currency']}).done(function(json){validResults['total_plus_child_budget_currency_value'] = json.output});
                        validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                        //Check reporting organization
                        if(!isEmpty(result.reporting_organisation)){
                            if(!isEmpty(result.reporting_organisation.narratives)){
                                validResults['reporting_organisations'] = result.reporting_organisation.narratives[0].text;
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
                        if(window.searchType == 'F'){
                            console.log(result.activity_plus_child_aggregation.totalBudget);
                            if(validResults['title'].length == 0){
                                validResults['title'] = 'Project Title Unavailable';
                            }
                            var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+'</a></h3><span>Reporting Organisation: <em>'+validResults['reporting_organisations']+'</em></span><span>Project Identifier: <em>'+ validResults['iati_identifier'] +'</em></span><span>Activity Status: <em>'+validResults['activity_status']+'</em></span><span class="budget">Total Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+result.activity_plus_child_aggregation.totalBudget+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        }
                        else{
                            var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+'</a></h3><span>Reporting Organisation: <em>'+validResults['reporting_organisations']+'</em></span><span>Project Identifier: <em>'+ validResults['iati_identifier'] +'</em></span><span>Activity Status: <em>'+validResults['activity_status']+'</em></span><span class="budget">Total Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+validResults['total_plus_child_budget_value']+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                        }
                        //$('.modal').hide();
                        $('#showResults').append(tempString);
                    });
                })
                .fail(function(error){
                    $('#showResults').text(error.toSource());
                    console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
                })
                .complete(function(){
                    generateBudgetValues();
                });
            }
        });
        // $('.search-result h3 a small[class^="GB-"]').parent().parent().parent().show();
        // $('.search-result h3 a small[class^="XM-DAC-12-"]').parent().parent().parent().show();
    };

    function generateBudgetValues(){
        $('.tpcbcv').each(function(){
            var temp_amount = $(this).children('.total_plus_child_budget_currency_value_amount').text();
            if(window.searchType == 'F'){
                $(this).before(temp_amount);
            }
            else{
                $(this).before('£' + addCommas(temp_amount));
            }
        });
    };

    // Backup of old code for emergency Fallback.
    // function generateBudgetValues(){
    //     $('.tpcbcv').each(function(){
    //         var temp_amount = $(this).children('.total_plus_child_budget_currency_value_amount').text();
    //         var temp_currency = $(this).children('.total_plus_child_budget_currency_value_cur').text();
    //         var temp_response = '';
    //         //$(this).parent().prepend('<span class="remove_loader">Loading total budget..</span>');
    //         $.ajax({
    //             method: "GET",
    //             async: false,
    //             url: "/currency",
    //             data: {amount: temp_amount, currency: temp_currency},
    //         }).done(function(msg){
    //             //console.log("saved: " + msg.output);
    //             temp_response = msg.output;
    //         });
    //         //$(this).parent().children('.remove_loader').remove();
    //         $(this).before(temp_response);
    //     });
    // };

    /*generateProjectListAjax function re-populates the project list based on the new api call when clicked on a filter or order*/

    function generateProjectListAjax(oipaLink){
        console.log(oipaLink);
        $('#showResults').animate({opacity: 0.4},500,function(){
            $('.modal').show();
        });
        $.getJSON(oipaLink,{
            format: "json",
            async: false,
        })
        .done(function(json){
            $('#showResults').animate({opacity: 1},500,function(){
                $('.modal').hide();
            });
            if(window.searchType == 'F'){
                $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 10px;">Default filter shows currently active projects. To see projects at other stages, either use the status filters or select the checkbox to search for completed projects.</div>');
                json = json.output;
            }
            else{
                $('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 10px;">Default filter shows currently active projects. To see projects at other stages, use the status filters.</div>');
            }

            //$('#showResults').html('<div class="ui-state-highlight ui-corner-all" style="margin-top: 20px; padding: 0.5em 0.7em 0em;"><p><span style="float: left; margin-right: .3em;" class="ui-icon ui-icon-info"></span>Default filter shows currently active projects. To see projects at other stages, use the status filters.</p></div>');
            returnedProjectCount = json.count;
            // Moved the refreshPagination execution to a later state as part of code optimisation
            //refreshPagination(json.count);
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
                validResults['id'] = !isEmpty(result.id) ? result.id : "";
                console.log(validResults['iati_identifier'])
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
                validResults['total_plus_child_budget_value'] = !isEmpty(result.activity_plus_child_aggregation.activity_children.budget_value) ? result.activity_plus_child_aggregation.activity_children.budget_value : 0;
                validResults['total_plus_child_budget_currency'] = !isEmpty(result.activity_plus_child_aggregation.activity_children.budget_currency) ? result.activity_plus_child_aggregation.activity_children.budget_currency : !isEmpty(result.activity_plus_child_aggregation.activity_children.incoming_funds_currency)? result.activity_plus_child_aggregation.activity_children.incoming_funds_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.expenditure_currency)? result.activity_plus_child_aggregation.activity_children.expenditure_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.disbursement_currency)? result.activity_plus_child_aggregation.activity_children.disbursement_currency: !isEmpty(result.activity_plus_child_aggregation.activity_children.commitment_currency)? result.activity_plus_child_aggregation.activity_children.commitment_currency: "GBP";
                validResults['total_plus_child_budget_currency_value'] = '';
                //$.getJSON(currencyLink,{amount: validResults['total_plus_child_budget_value'], currency: validResults['total_plus_child_budget_currency']}).done(function(json){validResults['total_plus_child_budget_currency_value'] = json.output});
                validResults['activity_status'] = !isEmpty(result.activity_status.name) ? result.activity_status.name : "";
                //Check reporting organization
                if(!isEmpty(result.reporting_organisation)){
                    if(!isEmpty(result.reporting_organisation.narratives)){
                        validResults['reporting_organisations'] = result.reporting_organisation.narratives[0].text;
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
                if(window.searchType == 'F'){
                    console.log(result.activity_plus_child_aggregation.totalBudget);
                    var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+'</a></h3><span>Reporting Organisation: <em>'+validResults['reporting_organisations']+'</em></span><span>Project Identifier: <em>'+ validResults['iati_identifier'] +'</em></span><span>Activity Status: <em>'+validResults['activity_status']+'</em></span><span class="budget">Total Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+result.activity_plus_child_aggregation.totalBudget+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                }
                else{
                    var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+'</a></h3><span>Reporting Organisation: <em>'+validResults['reporting_organisations']+'</em></span><span>Project Identifier: <em>'+ validResults['iati_identifier'] +'</em></span><span>Activity Status: <em>'+validResults['activity_status']+'</em></span><span class="budget">Total Budget: <em> '+'<div class="tpcbcv"><span class="total_plus_child_budget_currency_value_amount">'+validResults['total_plus_child_budget_value']+'</span><span class="total_plus_child_budget_currency_value_cur">'+validResults['total_plus_child_budget_currency']+'</span></div>'+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                }
                $('#showResults').append(tempString);
            });
            refreshPagination(json.count);
        })
        .fail(function(error){
            console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
        })
        .complete(function(){
            generateBudgetValues();
        });
    };

    /*This method attaches the +/- sign to the relevant filter expansion label*/
    function attachFilterExpColClickEvent(){
       $('.proj-filter-exp-collapse-sign').click(function(){
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
       //$('#status-filter').children('.proj-filter-exp-collapse-text').click();
    }
    attachFilterExpColClickEvent();
    $('#status-filter').children('.proj-filter-exp-collapse-text').click();
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
    // $( document ).ajaxStart(function() {
    //     $('.modal').show();
    // });
    // $( document ).ajaxStop(function() {
    //     $('.modal').hide();
    // });
    function isEmpty(val){
        return (val === undefined || val == null || val.length <= 0) ? true : false;
    }
});