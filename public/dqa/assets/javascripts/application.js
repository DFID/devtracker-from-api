//
// For guidance on how to add JavaScript see:
// https://prototype-kit.service.gov.uk/docs/adding-css-javascript-and-images
//


// (function a() {
//     a();
// })();

// DASHBOARD SHOW/HIDE CONTENT
// document.getElementById("sort_Organisation").addEventListener("change", function() {
//      const value = this.value;
//      const div = document.getElementById("FCDO_content");

//      if (value === "Department for Energy, Security and Net Zero") {
//           div.style.display = "none";
//      } else {
//           div.style.display = "block";
//      }
// });

/// Add class on scroll
function checkScroll() {
     const elements = document.querySelectorAll(".bar_chart");

     elements.forEach(function(element) {
          const rect = element.getBoundingClientRect();

          if (rect.top < window.innerHeight) {
               element.classList.add("in-view");
          }
     });
}

window.addEventListener("scroll", checkScroll);
window.addEventListener("load", checkScroll);

window.GOVUKPrototypeKit.documentReady(() => {
     // Add JavaScript here


     // Add class on scrolls
     function isElementInViewport(el) {
          const rect = el.getBoundingClientRect();
          return (
               rect.top >= 0 &&
               rect.left >= 0 &&
               rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
               rect.right <= (window.innerWidth || document.documentElement.clientWidth)
          );
     }

     if (document.getElementById("dashboard_V0")) {
          document.body.classList.add("original_devtracker");
     }

     // Show tab 3    
     document.querySelector(".tab_section_3").addEventListener("click", function() {
          document.getElementById("tab_content_3").style.display = "block";
          document.getElementById("tab_content_3").scrollIntoView({ behavior: "smooth"});
          document.getElementById("tab_content_4").style.display = "none";
          document.getElementById("dashboard_V1_content").classList.add("active");
          
     });

     document.querySelectorAll(".tab_section_3").forEach(function(el) {
          el.addEventListener("click", function() {
               this.classList.add("active"); // "this" refers to the clicked element
               document.querySelector(".tab_section_4").classList.remove("active");
          });
     });
     
     // Show tab 4
     document.querySelector(".tab_section_4").addEventListener("click", function() {
          document.getElementById("tab_content_3").style.display = "none";
          document.getElementById("tab_content_4").style.display = "block";
          document.getElementById("tab_content_4").scrollIntoView({ behavior: "smooth"});
          document.getElementById("dashboard_V1_content").classList.add("active");
     });

     document.querySelectorAll(".tab_section_4").forEach(function(el) {
          el.addEventListener("click", function() {
               this.classList.add("active"); // "this" refers to the clicked element
               document.querySelector(".tab_section_3").classList.remove("active");
          });
     });

     document.querySelector(".non_anchor_tag").addEventListener("click", function(event) {
          event.preventDefault();
     });    

})

