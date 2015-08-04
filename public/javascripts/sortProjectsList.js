(function($, undefined){
    $("document").ready(function (){

        $('#sortProjTitle').on('click',function(e){
            if($(this).text()=="▼")
            {
                sortByTitle('asc');
                $(this).text('▲');
            }
            else
            {
                sortByTitle('dsc');
                $(this).text('▼');
            }

            setDefaultBorder();
            $(this).css('border', "solid 1px #FFA500");
            e.preventDefault();
        });

        $('#sortProjBudg').click(function(e){
            if($(this).text()=="▼")
            {
                sortByBudget('asc');
                $(this).text('▲');
            }
            else
            {
                sortByBudget('dsc');
                $(this).text('▼');
            }

            setDefaultBorder();
            $(this).css('border', "solid 1px #FFA500");
            e.preventDefault();
        });

    });

    function setDefaultBorder(){
        $(".sort-proj-sectors").each(function(){
            $(this).css('border', "none");
        });
    }

    function sortByBudget(order){

        var containerDiv = $('#search-results');
        var childResultDivs = containerDiv.children('.search-result').get();

        childResultDivs.sort(function (a, b){
            var compA = parseInt( $(a).find('.sort-budget').val());
            var compB = parseInt( $(b).find('.sort-budget').val());

            if(order=='asc')
                return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
            else
                return (compA < compB) ? 1 : (compA > compB) ? -1 : 0;
        })

        $.each(childResultDivs, function(idx, item){containerDiv.append(item);});
    }

    function sortByTitle(order){

        var containerDiv = $('#search-results');
        var childResultDivs = containerDiv.children('.search-result').get();

        childResultDivs.sort(function (a, b){
            var compA = $(a).find('.sort-title').val().toString();
            var compB = $(b).find('.sort-title').val().toString();

            if(order=='asc')
                return (compA.toLowerCase() < compB.toLowerCase()) ? -1 : (compA.toLowerCase() > compB.toLowerCase()) ? 1 : 0;
            else
                return (compA.toLowerCase() < compB.toLowerCase()) ? 1 : (compA.toLowerCase() > compB.toLowerCase()) ? -1 : 0;
        })

        $.each(childResultDivs, function(idx, item){containerDiv.append(item);});
    }
})(jQuery)