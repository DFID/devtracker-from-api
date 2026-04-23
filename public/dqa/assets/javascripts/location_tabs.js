// LOCATION TABS

// Show tab 1    
document.querySelector(".tab_location_1").addEventListener("click", function() {
     document.getElementById("location_content_1").style.display = "block";
     document.getElementById("location_content_1").scrollIntoView({ behavior: "smooth"});
     document.getElementById("location_content_2").style.display = "none";
     document.getElementById("dashboard_V1_content").classList.add("active");
     
});

document.querySelectorAll(".tab_location_1").forEach(function(el) {
     el.addEventListener("click", function() {
          this.classList.add("active"); // "this" refers to the clicked element
          document.querySelector(".tab_location_2").classList.remove("active");
     });
});

// Show tab 4
document.querySelector(".tab_location_2").addEventListener("click", function() {
     document.getElementById("location_content_1").style.display = "none";
     document.getElementById("location_content_2").style.display = "block";
     document.getElementById("location_content_2").scrollIntoView({ behavior: "smooth"});
     document.getElementById("dashboard_V1_content").classList.add("active");
});

document.querySelectorAll(".tab_location_2").forEach(function(el) {
     el.addEventListener("click", function() {
          this.classList.add("active"); // "this" refers to the clicked element
          document.querySelector(".tab_location_1").classList.remove("active");
     });
});

document.querySelector(".non_anchor_tag").addEventListener("click", function(event) {
     event.preventDefault();
});    


