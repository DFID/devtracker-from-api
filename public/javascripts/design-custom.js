$(document).ready(function () {
  $(".app-modal--open").click(function (e) {
    $(".app-modal").addClass("app-modal--active");
    e.preventDefault();
  });


  $(".app-modal--cancel").click(function (e) {
    $(".app-modal").removeClass("app-modal--active");
    e.preventDefault();
  });
});

$(document).click(function (event) {
  //event.preventDefault();
  //if you click on anything except the modal itself or the "open modal" link, close the modal
  if (!$(event.target).closest(".app-modal .app-modal-content, .app-modal--open").length) {
    $("body").find(".app-modal").removeClass("app-modal--active");
  }
});