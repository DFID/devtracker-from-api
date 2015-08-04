(function($){
 $.fn.showmore = function(options) {
 	var defaults = {
		limit: 140,
		marginTop: 0,
		expandText:         '<a href="#">Show More</a>',
    	userCollapseText:   '<a href="#">Show Less</a>'
	};

 	var options = $.extend(defaults, options);
	return this.each(function() {
        var container = $(this);
        var hide = false;
        container.append('<div class="divShowAll">'+options.expandText+'</div>');
        container.append('<div class="divHideAll">'+options.userCollapseText+'</div>');
        $(".divHideAll", $(this)).click(function(event){
            var h = 0;
            $(event.currentTarget).parent().find("li.entry").each(function(i){
                h+=$(this).height()+options.marginTop;
                if(options.limit<h){
                    $(this).hide();
                    hide=true;
                }
            });
            if(hide==true){
                $(".divHideAll", $(event.currentTarget).parent()).hide();
                $(".divShowAll", $(event.currentTarget).parent()).show();
            }else{
                $(".divHideAll", $(event.currentTarget).parent()).hide();
                $(".divShowAll", $(event.currentTarget).parent()).hide();
            }

            return false
        });

        $(this).find('div[class="divShowAll"]').click(function(event){
            $(event.currentTarget).parent().find("li.entry").each(function(i){
                $(this).show();
            });
            $(".divHideAll", $(event.currentTarget).parent()).show();
            $(".divShowAll", $(event.currentTarget).parent()).hide();

            return false;
        });

        $(".divHideAll", $(this)).click();
	});
 };
})(jQuery);