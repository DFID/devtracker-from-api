$(document).ready(function() {

  $(".show-advance-button").click(function(e){
    $(".advance-toggle").addClass("active");
    e.preventDefault();
  });


  $(".close-advance-button").click(function(e){
    $(".advance-toggle").removeClass("active");
    e.preventDefault();
  });
});

$(document).click(function(event) {
	//event.preventDefault();
  //if you click on anything except the modal itself or the "open modal" link, close the modal
  if (!$(event.target).closest(".advance-toggle .inner,.show-advance-button").length) {
    $("body").find(".advance-toggle").removeClass("active");
  }
});