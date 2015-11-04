$(document).ready(function() {
    refreshPagination(window.project_count);
    var oipaLink = window.oipaApiUrl + 'activities?hierarchy=1&page_size=10&format=json&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations,description&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val();
    function refreshOipaLink(){
        oipaLink = window.oipaApiUrl + 'activities?hierarchy=1&page_size=10&format=json&fields=activity_status,iati_identifier,url,title,reporting_organisations,activity_aggregations,description&q='+window.searchQuery+'&activity_status='+$('#activity_status_states').val();
    };
    var returnedProjectCount = 0;
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
                        validResults['description'] = !isEmpty(result.description[0]) ? result.description[0].narratives[0].text : "";
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
    $('.activity_status').click(function(){
        var tmpStatusList = $('.activity_status:checked').map(function(){return $(this).val()}).get().join();
        if(tmpStatusList.length > 0){
            $('#activity_status_states').val(tmpStatusList);
        }
        else{
            $('#activity_status_states').val('1,2,3,4,5');
        }
        refreshOipaLink();
        generateProjectListAjax(oipaLink);
    });
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
                validResults['description'] = !isEmpty(result.description[0]) ? result.description[0].narratives[0].text : "";
                var tempString = '<div class="search-result"><h3><a href="/projects/'+validResults['iati_identifier']+'">'+validResults['title']+' <small>['+ validResults['iati_identifier'] +']</small></a></h3><span class="budget">Budget: <em> £'+addCommas(validResults['total_child_budget_value'])+'</em></span><span>Status: <em>'+validResults['activity_status']+'</em></span><span>Reporting Org: <em>'+validResults['reporting_organisations']+'</em></span><p class="description">'+validResults['description']+'</p></div>';
                $('#showResults').append(tempString);
            });
        })
        .fail(function(error){
            //$('#showResults').text(error.toSource());
            console.log("AJAX error in request: " + JSON.stringify(error, null, 2));
        });
    }
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