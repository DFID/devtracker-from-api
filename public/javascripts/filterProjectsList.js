(function($, undefined){

  $(document).ready(function(){

    getHiddenFieldsValues();
    sortFilters();
    addCheckboxesFilters();
    setOnChange();
    attachFilterExpColClickEvent();
    budgetFilteringSetUp();
    dateFilteringSetUp();

  });

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

  function hasTrue(array) {
    return ($.inArray(true, array)!= -1);
  }

function dateFilteringSetUp(){

    var divsToCheck = $('input[name=status][type="hidden"]').parent('div');
    var minStartDt = new Date();
    var maxEndDt = new Date();

    $( "input[name=dateStart][type='hidden']" ).each(function(i, input){
      var dt = new Date(0);
      dt = dt.setUTCMilliseconds(input.value);
      dt = new Date(dt);

      if(minStartDt > dt && parseInt(input.value)>0){
        minStartDt = dt;
      }
    });

    maxEndDt = minStartDt;
    $( "input[name=dateEnd][type='hidden']" ).each(function(i, input){
      var dt = new Date(0);
      dt = dt.setUTCMilliseconds(input.value);
      dt = new Date(dt);

      if(maxEndDt < dt && parseInt(input.value)>0){
        maxEndDt = dt;
      }
    });

    $("#date-slider-vertical").slider({
       orientation: "horizontal",
       range:true,
       min: Date.parse(minStartDt),
       max: Date.parse(maxEndDt),
       step: 86400000,
       values: [Date.parse(minStartDt), Date.parse(maxEndDt)],
       slide: function(event, ui){


        var startDt = new Date(ui.values[0]);
        var endDt = new Date(ui.values[1]);
        $('#date-range').html(startDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + endDt.customFormat("#DD# #MMM# #YYYY#"));
       },
       change: function( event, ui ) {

        $(".search-result").each(function(i, div) {
            var self = $(this);

            var startDtElVal = parseInt(self.children("input[name='dateStart']").val());
            var endDtElVal = parseInt(self.children("input[name='dateEnd']").val());


            if (startDtElVal <= 0 && endDtElVal > 0 && endDtElVal <= parseInt(ui.values[1])){
                self.show();
            }
            else if(endDtElVal <= 0 && startDtElVal > 0 && startDtElVal >= parseInt(ui.values[0])) {
                self.show();
            }
            else if (startDtElVal > 0 && endDtElVal > 0 && startDtElVal >= parseInt(ui.values[0]) && endDtElVal <= parseInt(ui.values[1]) ) {
              self.show();
            }
            else {
              self.hide();
            }
        });
        displayResultsAmount();
       }
    });

    $('#date-range').html(minStartDt.customFormat("#DD# #MMM# #YYYY#") + ' - ' + maxEndDt.customFormat("#DD# #MMM# #YYYY#"));

}

  function budgetFilteringSetUp() {
    var divsToCheck = $('input[name=status][type="hidden"]').parent('div');
    var max = 0;
    var min = 0;
    $( "input[name=budget][type='hidden']" ).each(function(i, input){
      if(max < input.value){
        max = +(input.value);
      }
    });

    $( "#slider-vertical" ).slider({
      orientation: "horizontal",
      range: true,
      min: min,
      max: max,
      step : (Math.round(max / 100) * 100)/100,
      values: [min,max],
      slide: function( event, ui ) {
        $( "#amount" ).html( (""+ui.values[0]).replace(/(\d)(?=(?:\d{3})+$)/g, "$1,")+" - "+ (""+ui.values[1]).replace(/(\d)(?=(?:\d{3})+$)/g, "$1,"));
      },
      change: function( event, ui ) {

        if (!$('input[type=checkbox]').is(':checked')) {
          $(".search-result").each(function(i, div) {
            var self = $(this);
            if ( (self.children("input[name='budget']").val() <= ui.values[1]) && 
                 (self.children("input[name='budget']").val() >= ui.values[0]) ) {
              self.show();
            } else {
              self.hide();
            }
          });
        } else {
          filter(divsToCheck);
        }
        displayResultsAmount();
      }
    });

    $("#amount").html( ("" + min).replace(/(\d)(?=(?:\d{3})+$)/g, "$1,") +" - "+(""+max).replace(/(\d)(?=(?:\d{3})+$)/g, "$1,"));
  }

  function filter(divsToCheck) {
    if( !$('input[type=checkbox]').is(':checked') && ($('#slider-vertical').slider("option", "values")[1] == $('#slider-vertical').slider("option", "max")) ) {
      $('.search-result').show();
      displayResultsAmount();
      return false;
    }

    divsToCheck.each(function(i, div) {
      var anythingFound = false;    
      var budget = 0;

      var hasStatus = [];
      var isStatusGroupActive = false;
      $('input:checked[name=status]').each(function(i, checkboxess) {
        anythingFound = true;
        isStatusGroupActive = true;
        if ($(div).children('input[value*="'+checkboxess.value+'"][name="status"]').length > 0) {
          hasStatus.push(true);
        }
      });
       
      var hasOrganisations = [];    
      var isOrganisationsGroupActive = false;    
      $('input:checked[name=organizations]').each(function(i, checkboxess) {
        anythingFound = true;
        isOrganisationsGroupActive = true;
        if ($(div).children('input[value*="'+checkboxess.value+'"][name="organizations"]').length > 0) {
          hasOrganisations.push(true);
        }
      });

      var hasSectors = [];
      var isSectorsGroupActive = false;
      $('input:checked[name=sectors]').each(function(i, checkboxess) {
        anythingFound = true;
        isSectorsGroupActive = true;
        if ($(div).children('input[value*="'+checkboxess.value+'"][name="sectors"]').length > 0) {
          hasSectors.push(true);
        }
      });

      var hasCountry = [];
      var isCountryGroupActive = false;
      $('input:checked[name=countries]').each(function(i, checkboxes){
        anythingFound = true;
        isCountryGroupActive = true;
        if ($(div).children('input[value*="' + checkboxes.value + '"][name="countries"]').length > 0) {
          hasCountry.push(true);
        }
      });

      var hasRegion = [];
      var isRegionGroupActive = false;
      $('input:checked[name=regions]').each(function(i, checkboxes){
        anythingFound = true;
        isRegionGroupActive = true;
        if ($(div).children('input[value*="' + checkboxes.value + '"][name="regions"]').length > 0) {
          hasRegion.push(true);
        }
      });

      var hasDocuments = [];
      var isDocumentsGroupActive = false;
      $('input:checked[name=documents]').each(function(i, checkboxes){
          anythingFound = true;
          isDocumentsGroupActive = true;
          if ($(div).children('input[value*="' + checkboxes.value + '"][name="documents"]').length > 0) {
            hasDocuments.push(true);
          }
      });
           
      var show = [];
      if(isStatusGroupActive){
        show.push(hasTrue(hasStatus));
      }

      if(isOrganisationsGroupActive){
        show.push(hasTrue(hasOrganisations));
      }

      if(isSectorsGroupActive){
        show.push(hasTrue(hasSectors));
      }

      if(isRegionGroupActive || isCountryGroupActive){
        show.push(hasTrue(hasRegion) || hasTrue(hasCountry))
      }

      var divBudget = +($(div).children('input[name="budget"]').val());
      var min = +($('#slider-vertical').slider("option", "values")[0]);
      var max = +($('#slider-vertical').slider("option", "values")[1]);
      if (divBudget > max || divBudget < min) {
        show.push(false);
      } 

      if(isDocumentsGroupActive){
        show.push(hasTrue(hasDocuments));
      }

      if ($.inArray(false, show)!= -1) {
        $(div).hide();
      } else {
        $(div).show();
      }

      if(!anythingFound){
        $('.search-result').css("display", "none");
      }
    });
    displayResultsAmount();
  }

  function setOnChange(){
    var divsToCheck = $('input[name=status][type="hidden"]').parent('div');
    $('input[type=checkbox]').change(function() {
      filter(divsToCheck);
    });
  }

  function displayResultsAmount(){
    $('span[name=afterFilteringAmount]').html(($(".search-result").length - $(".search-result:hidden").length) + " of ");
  }

  var Status = [];
  var Countries = [];
  var Regions = [];
  var Organizations = [];
  var Sectors = [];
  var SectorGroups = [];
  var Documents = [];

  function unique(array){
    return $.grep(array,function(el,index) {
      return index == $.inArray(el,array);
    });
  }

  function SortByName(a, b) {
    var aName = a.toLowerCase();
    var bName = b.toLowerCase(); 
    return ((aName < bName) ? -1 : ((aName > bName) ? 1 : 0));
  }

  function sortFilters(){
    Status        = Status.sort(SortByName);
    Sectors       = Sectors.sort(SortByName);
    Countries     = Countries.sort(SortByName);
    Regions       = Regions.sort(SortByName);
    Organizations = Organizations.sort(SortByName);
    Documents     = Documents.sort(SortByName);
  }

  function splitAndAssign(string, outputArray) {
    var splited = string.split('#');
    $.each(splited, function(i,val) {
      if ( val.length > 0) { 
        if ($.inArray(val, outputArray)==-1) {
          outputArray.push(val); 
        }
      }
    });
  }

  function getHiddenFieldsValues(){
    $(".search-result input[name=status]").each(function() {
      splitAndAssign($(this).attr("value"),Status)
    });

    $(".search-result input[name=sectors]").each(function() {
      splitAndAssign($(this).attr("value"),Sectors)
    });

    $(".search-result input[name=organizations]").each(function() {
      splitAndAssign($(this).attr("value"),Organizations)
    });

    $(".search-result input[name=countries]").each(function() {
      splitAndAssign($(this).attr("value"),Countries)
    });

    $(".search-result input[name=regions]").each(function() {
      splitAndAssign($(this).attr("value"),Regions)
    });

    $(".search-result input[name=documents]").each(function() {
       splitAndAssign($(this).attr("value"),Documents)
    });
  }

  function addCheckboxesFilters() {

    $("div[name=status], div[name=sectors], div[name=organizations], div[name=regions], div[name=countries], div[name=documents]").append("<ul></ul>")

    if(Status.length < 2) {
      $("div[name=status]").hide()
    } else {
      $.each( Status, function( key, value ) {
        $("div[name=status] ul").append(createInputCheckbox('status', value));
      });
      $("div[name=status] ul").css('display', 'none');
    }

    if(Sectors.length < 2) {
      $("div[name=sectors]").hide()
    }else{
      $.each( Sectors, function( key, value ) {
        $("div[name=sectors] ul").append(createInputCheckbox('sectors', value));
      });
      $("div[name=sectors] ul").css('display', 'none');
    }

    if(Organizations.length < 2) {
      $("div[name=organizations]").hide()
    } else {
      $.each( Organizations, function( key, value ) {
        $("div[name=organizations] ul").append(createInputCheckbox('organizations', value));
      });
      $("div[name=organizations] ul").css('display', 'none');
    }

    if(Countries.length < 2) {
      $("div[name=countries]").hide()
    } else {
      $.each( Countries, function( key, value ) {
        $("div[name=countries] ul").append(createInputCheckbox('countries', value));
      });
      $("div[name=countries] ul").css('display', 'none');
    }

    if(Regions.length < 2) {
      $("div[name=regions]").hide()
    } else {
      $.each( Regions, function( key, value ) {
        $("div[name=regions] ul").append(createInputCheckbox('regions', value));
      });
      $("div[name=regions] ul").css('display', 'none');
    }

    if(Documents.length < 2) {
      $("div[name=documents]").hide()
    } else {
      $.each( Documents, function( key, value ) {
       $("div[name=documents] ul").append(createInputCheckbox('documents', value));
      });
      $("div[name=documents] ul").css('display', 'none');
    }

    if(Countries.length < 2 && Regions.length < 2)
     $("div[name=locations]").hide() ;

  }

  function createInputCheckbox(name, value) {
    var uid = Math.floor(Math.random()*100000000) + "";
    return "<li>" +
      "<label title='"+ value + "' for='"+ uid +"' style='white-space:nowrap; text-overflow: ellipsis; overflow: hidden;'>" + 
        "<input type='checkbox' name='"+name+"' id='"+ uid +"' value='"+value+"'/>" + value +
      "</label>" +
    "</li>";
  }
})(jQuery)
