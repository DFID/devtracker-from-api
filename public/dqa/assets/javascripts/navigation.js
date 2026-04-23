// NAVIGATION

// SELECTED PAGE
if (document.getElementById("location_full_hero")) {
     document.querySelector("header .additionial_info").classList.remove("active_link");
     document.getElementById("location_nav_item").classList.add("active_link");
}

// NAV
// document.querySelector(".sub_nav_container").classList.toggle("active");

document.querySelector(".show_sub_nav_item_1").addEventListener("click", function() {
     // Nav Links
     this.classList.toggle("active");
     document.querySelector(".show_sub_nav_item_2").classList.remove("active");
     document.querySelector(".show_sub_nav_item_3").classList.remove("active");
     document.querySelector(".show_sub_nav_item_4").classList.remove("active");
     document.querySelector(".show_sub_nav_item_5").classList.remove("active");

     // Nav sections
     document.querySelector(".sub_nav_item.item_1").classList.toggle("active");
     document.querySelector(".sub_nav_item.item_2").classList.remove("active");
     document.querySelector(".sub_nav_item.item_3").classList.remove("active");
     document.querySelector(".sub_nav_item.item_4").classList.remove("active");
     document.querySelector(".sub_nav_item.item_5").classList.remove("active");
});

document.querySelector(".show_sub_nav_item_2").addEventListener("click", function() {
     // Nav Links
     document.querySelector(".show_sub_nav_item_1").classList.remove("active");
     this.classList.toggle("active");
     document.querySelector(".show_sub_nav_item_3").classList.remove("active");
     document.querySelector(".show_sub_nav_item_4").classList.remove("active");
     document.querySelector(".show_sub_nav_item_5").classList.remove("active");

     // Nav sections
     document.querySelector(".sub_nav_item.item_1").classList.remove("active");
     document.querySelector(".sub_nav_item.item_2").classList.toggle("active");
     document.querySelector(".sub_nav_item.item_3").classList.remove("active");
     document.querySelector(".sub_nav_item.item_4").classList.remove("active");
     document.querySelector(".sub_nav_item.item_5").classList.remove("active");
});

document.querySelector(".show_sub_nav_item_3").addEventListener("click", function() {
     // Nav Links
     document.querySelector(".show_sub_nav_item_1").classList.remove("active");
     document.querySelector(".show_sub_nav_item_2").classList.remove("active");
     this.classList.toggle("active");
     document.querySelector(".show_sub_nav_item_4").classList.remove("active");
     document.querySelector(".show_sub_nav_item_5").classList.remove("active");

     // Nav sections
     document.querySelector(".sub_nav_item.item_1").classList.remove("active");
     document.querySelector(".sub_nav_item.item_2").classList.remove("active");
     document.querySelector(".sub_nav_item.item_3").classList.toggle("active");
     document.querySelector(".sub_nav_item.item_4").classList.remove("active");
     document.querySelector(".sub_nav_item.item_5").classList.remove("active");
});

document.querySelector(".show_sub_nav_item_4").addEventListener("click", function() {
     // Nav Links
     document.querySelector(".show_sub_nav_item_1").classList.remove("active");
     document.querySelector(".show_sub_nav_item_2").classList.remove("active");
     document.querySelector(".show_sub_nav_item_3").classList.remove("active");
     this.classList.toggle("active");
     document.querySelector(".show_sub_nav_item_5").classList.remove("active");

     // Nav sections
     document.querySelector(".sub_nav_item.item_1").classList.remove("active");
     document.querySelector(".sub_nav_item.item_2").classList.remove("active");
     document.querySelector(".sub_nav_item.item_3").classList.remove("active");
     document.querySelector(".sub_nav_item.item_4").classList.toggle("active");
     document.querySelector(".sub_nav_item.item_5").classList.remove("active");
});

document.querySelector(".show_sub_nav_item_5").addEventListener("click", function() {
     // Nav Links
     document.querySelector(".show_sub_nav_item_1").classList.remove("active");
     document.querySelector(".show_sub_nav_item_2").classList.remove("active");
     document.querySelector(".show_sub_nav_item_3").classList.remove("active");
     document.querySelector(".show_sub_nav_item_4").classList.remove("active");
     this.classList.toggle("active");

     // Nav sections
     document.querySelector(".sub_nav_item.item_1").classList.remove("active");
     document.querySelector(".sub_nav_item.item_2").classList.remove("active");
     document.querySelector(".sub_nav_item.item_3").classList.remove("active");
     document.querySelector(".sub_nav_item.item_4").classList.remove("active");
     document.querySelector(".sub_nav_item.item_5").classList.toggle("active");
});

