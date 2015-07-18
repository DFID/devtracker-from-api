(function($, undefined){
    $("document").ready(function (){

        $('#sortSectName').on('click',function(e){
          if($(this).text()=="▼")
              {
                  sortBySctorName('asc');
                  $(this).text('▲');
              }
              else
              {
                  sortBySctorName('dsc');
                  $(this).text('▼');
              }

              setDefaultBorder();
              $(this).css('border', "solid 1px #FFA500");
              e.preventDefault();
        });

        $('#sortSectBudgPer').click(function(e){
            if($(this).text()=="▼")
                {
                    sortBySectorBudget('asc');
                    $(this).text('▲');
                }
                else
                {
                    sortBySectorBudget('dsc');
                    $(this).text('▼');
                }

                setDefaultBorder();
                $(this).css('border', "solid 1px #FFA500");
                e.preventDefault();
        });
    });

    function setDefaultBorder()
    {
        $(".sort-proj-sectors").each(function(){
            $(this).css('border', "none");
        });
    }

    function sortBySectorBudget(order){

        var containerDiv = $('ul.sector-list');
        var childResultDivs = containerDiv.children();

        childResultDivs.sort(function (a, b){

            var compA = parseFloat( $(a).find('div.progress').text());
            var compB = parseFloat( $(b).find('div.progress').text());

            if(order=='asc')
                return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
            else
                return (compA < compB) ? 1 : (compA > compB) ? -1 : 0;
        })

        $.each(childResultDivs, function(idx, item){containerDiv.append(item);});
    }

    function sortBySctorName(order){

        var containerDiv = $('ul.sector-list');
        var childResultDivs = containerDiv.children();

        childResultDivs.sort(function (a, b){

            var compA = $(a).find('.sort-sectorName').text().toString();
            var compB = $(b).find('.sort-sectorName').text().toString();

            if(order=='asc')
                return (compA.toLowerCase() < compB.toLowerCase()) ? -1 : (compA.toLowerCase() > compB.toLowerCase()) ? 1 : 0;
            else
                return (compA.toLowerCase() < compB.toLowerCase()) ? 1 : (compA.toLowerCase() > compB.toLowerCase()) ? -1 : 0;
        })

        $.each(childResultDivs, function(idx, item){containerDiv.append(item);});
    }
})(jQuery)