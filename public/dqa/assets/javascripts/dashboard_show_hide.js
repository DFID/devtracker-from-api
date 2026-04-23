// DASHBOARD SHOW/HIDE CONTENT
// document.getElementById("sort_Organisation").addEventListener("change", function() {
//      const value = this.value;
//      const div_FCDO = document.getElementById("FCDO_content");
//      const div_DESNZ = document.getElementById("DESNZ_content");
//      const div_LOADING = document.getElementById("dashboard_loading");
     

//      if (value === "Department for Energy, Security and Net Zero") {
//           div_FCDO.style.display = "none";
//           div_LOADING.style.display = "block";
//           setTimeout(function() {
//                div_LOADING.style.display = "none";
//                div_DESNZ.style.display = "block";
//           }, 1500);
//      } else if (value === "FCDO") {
//           div_DESNZ.style.display = "none";
//           div_LOADING.style.display = "block";
//           setTimeout(function() {
//                div_LOADING.style.display = "none";
//                div_FCDO.style.display = "block";
//           }, 1500);
//      }
// });

const sort_Organisation = document.getElementById("sort_Organisation");
const sort_Country = document.getElementById("sort_Country");
const sort_Sector = document.getElementById("sort_Sector");

const hero_number_A1 = document.getElementById("hero_number_A1");
const hero_number_A2 = document.getElementById("hero_number_A2");
const hero_number_A3 = document.getElementById("hero_number_A3");
const hero_number_B1 = document.getElementById("hero_number_B1");
const hero_number_B2 = document.getElementById("hero_number_B2");
const hero_number_B3 = document.getElementById("hero_number_B3");

const donut_number_C1 = document.getElementById("counter_1");
const donut_number_C2 = document.getElementById("counter_3");
const donut_number_C3 = document.getElementById("counter_5");
const donut_number_C4 = document.getElementById("counter_7");

function updateContent() {
     const organisationVal = sort_Organisation.value;
     const countryVal = sort_Country.value;
     const sectorVal = sort_Sector.value;

     const div_FCDO = document.getElementById("FCDO_content");
     const div_DESNZ = document.getElementById("DESNZ_content");
     const div_LOADING = document.getElementById("dashboard_loading");

     const div_DONUTS = document.getElementById("dashboard_V1_content");
     const div_CONTENT_LOADING = document.getElementById("dashboard_loading_content");

     if (organisationVal || countryVal || sectorVal) {
          div_DONUTS.style.display = "none";
          div_CONTENT_LOADING.style.display = "block";
          setTimeout(function() {
               div_DONUTS.style.display = "flex";
               div_CONTENT_LOADING.style.display = "none";
          }, 1000);
     }

     if (organisationVal == "FCDO") {
          donut_number_C1.innerHTML = `90`;
          donut_number_C2.innerHTML = `95`;
          donut_number_C3.innerHTML = `95`;
          donut_number_C4.innerHTML = `85`;     

          document.querySelector(".donut_1").classList.replace("size_eighty_five", "size_ninety");
          document.querySelector(".donut_2").classList.replace("size_ninety", "size_ninety_five");
          document.querySelector(".donut_3").classList.replace("size_eighty_five", "size_ninety_five");
          document.querySelector(".donut_4").classList.replace("size_ninety_five", "size_eighty_five");

          document.querySelector(".donut_1 .text").innerHTML = "Pass";
          document.querySelector(".donut_2 .text").innerHTML = "Pass";
          document.querySelector(".donut_3 .text").innerHTML = "Pass";
          document.querySelector(".donut_4 .text").innerHTML = "Fail";

          document.getElementById("full_hero_V2").classList.replace("desnz", "fcdo");
          
     } else if (organisationVal == "Department for Energy, Security and Net Zero") {
          donut_number_C1.innerHTML = `85`;
          donut_number_C2.innerHTML = `90`;
          donut_number_C3.innerHTML = `85`;
          donut_number_C4.innerHTML = `95`;   
          
          document.querySelector(".donut_1").classList.replace("size_ninety", "size_eighty_five");
          document.querySelector(".donut_2").classList.replace("size_ninety_five", "size_ninety");
          document.querySelector(".donut_3").classList.replace("size_ninety_five", "size_eighty_five");
          document.querySelector(".donut_4").classList.replace("size_eighty_five", "size_ninety_five");

          document.querySelector(".donut_1 .text").innerHTML = "Fail";
          document.querySelector(".donut_2 .text").innerHTML = "Pass";
          document.querySelector(".donut_3 .text").innerHTML = "Fail";
          document.querySelector(".donut_4 .text").innerHTML = "Pass";

          document.getElementById("full_hero_V2").classList.replace("fcdo", "desnz");
          
     }

     // if (countryVal == "All") {
     //      document.querySelector(".sector_location").innerHTML = "All";
     // } else if (countryVal == "Algeria") {
     //      document.querySelector(".sector_location").innerHTML = "Algeria";
     // } else if (countryVal == "Bangladesh") {
     //      document.querySelector(".sector_location").innerHTML = "Bangladesh";
     // }

     // if (sectorVal == "All") {
     //      document.querySelector(".sector_name").innerHTML = "All";
     // } else if (sectorVal == "Environment") {
     //      document.querySelector(".sector_name").innerHTML = "Environment";
     // } else if (sectorVal == "Health") {
     //      document.querySelector(".sector_name").innerHTML = "Health";
     // }


     // FCDO Values
     if (organisationVal === "FCDO" && countryVal === "All" && sectorVal === "All") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "All";
          document.getElementById("FCDO_sector_name").innerHTML = "All";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";

          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
          
     } else if (organisationVal === "FCDO" && countryVal === "Algeria" && sectorVal === "All") {
          hero_number_A1.innerHTML = `52`;
          hero_number_A2.innerHTML = `79`;
          hero_number_A3.innerHTML = `£1.7m`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Algeria";
          document.getElementById("FCDO_sector_name").innerHTML = "All";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "FCDO" && countryVal === "Algeria" && sectorVal === "Environment") {
          hero_number_A1.innerHTML = `10`;
          hero_number_A2.innerHTML = `5`;
          hero_number_A3.innerHTML = `£1m`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Algeria";
          document.getElementById("FCDO_sector_name").innerHTML = "Environment";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "FCDO" && countryVal === "Algeria" && sectorVal === "Health") {
          hero_number_A1.innerHTML = `2`;
          hero_number_A2.innerHTML = `3`;
          hero_number_A3.innerHTML = `£50k`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Algeria";
          document.getElementById("FCDO_sector_name").innerHTML = "Health";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "FCDO" && countryVal === "Bangladesh" && sectorVal === "All") {
          hero_number_A1.innerHTML = `111`;
          hero_number_A2.innerHTML = `2,830`;
          hero_number_A3.innerHTML = `£1.70bn`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Bangladesh";
          document.getElementById("FCDO_sector_name").innerHTML = "All";
          
          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "FCDO" && countryVal === "Bangladesh" && sectorVal === "Environment") {
          hero_number_A1.innerHTML = `0`;
          hero_number_A2.innerHTML = `0`;
          hero_number_A3.innerHTML = `£0`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Bangladesh";
          document.getElementById("FCDO_sector_name").innerHTML = "Environment";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "FCDO" && countryVal === "Bangladesh" && sectorVal === "Health") {
          hero_number_A1.innerHTML = `25`;
          hero_number_A2.innerHTML = `65`;
          hero_number_A3.innerHTML = `£2.5bn`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("FCDO_sector_location").innerHTML = "Bangladesh";
          document.getElementById("FCDO_sector_name").innerHTML = "Health";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "block";
               div_DESNZ.style.display = "none";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "All" && sectorVal === "All") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `245`;
          hero_number_B2.innerHTML = `1,259`;
          hero_number_B3.innerHTML = `£2.45bn`;

          document.getElementById("DESNZ_sector_location").innerHTML = "All";
          document.getElementById("DESNZ_sector_name").innerHTML = "All";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Algeria" && sectorVal === "All") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `15`;
          hero_number_B2.innerHTML = `3`;
          hero_number_B3.innerHTML = `£100k`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Algeria";
          document.getElementById("DESNZ_sector_name").innerHTML = "All";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Algeria" && sectorVal === "Environment") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `5`;
          hero_number_B2.innerHTML = `1`;
          hero_number_B3.innerHTML = `£5k`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Algeria";
          document.getElementById("DESNZ_sector_name").innerHTML = "Environment";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Algeria" && sectorVal === "Health") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `0`;
          hero_number_B2.innerHTML = `0`;
          hero_number_B3.innerHTML = `£0`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Algeria";
          document.getElementById("DESNZ_sector_name").innerHTML = "Health";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Bangladesh" && sectorVal === "All") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `13`;
          hero_number_B2.innerHTML = `7`;
          hero_number_B3.innerHTML = `£1.15bn`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Bangladesh";
          document.getElementById("DESNZ_sector_name").innerHTML = "All";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Bangladesh" && sectorVal === "Environment") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `2`;
          hero_number_B2.innerHTML = `3`;
          hero_number_B3.innerHTML = `£1m`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Bangladesh";
          document.getElementById("DESNZ_sector_name").innerHTML = "Environment";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } else if (organisationVal === "Department for Energy, Security and Net Zero" && countryVal === "Bangladesh" && sectorVal === "Health") {
          hero_number_A1.innerHTML = `693`;
          hero_number_A2.innerHTML = `5,089`;
          hero_number_A3.innerHTML = `£7.30bn`;

          hero_number_B1.innerHTML = `1`;
          hero_number_B2.innerHTML = `1`;
          hero_number_B3.innerHTML = `£150k`;

          document.getElementById("DESNZ_sector_location").innerHTML = "Bangladesh";
          document.getElementById("DESNZ_sector_name").innerHTML = "Health";

          div_FCDO.style.display = "none";
          div_DESNZ.style.display = "none";
          div_LOADING.style.display = "block";
          setTimeout(function() {
               div_FCDO.style.display = "none";
               div_DESNZ.style.display = "block";
               div_LOADING.style.display = "none";
          }, 1000);
     } 

     // DESNZ
}

// Listen to both selects
sort_Organisation.addEventListener("change", updateContent);
sort_Country.addEventListener("change", updateContent);
sort_Sector.addEventListener("change", updateContent);

// MODAL - V1 CODE
const modalV1 = document.getElementById("dashboard_helptext_V1");
const openBtnV1 = document.getElementById("openModal_V1");
const closeBtnV1 = document.getElementById("closeBtn_V1");

// Open modal
openBtnV1.addEventListener("click", function() {
     modalV1.style.display = "block";
});

// Close modal
closeBtnV1.addEventListener("click", function() {
     modalV1.style.display = "none";
});

// Close when clicking outside
window.addEventListener("click", function(e) {
     if (e.target === modalV1) {
          modalV1.style.display = "none";
     }
});

// MODAL - V2 CODE
const modalV2 = document.getElementById("dashboard_helptext_V2");
const openBtnV2 = document.getElementById("openModal_V2");
const closeBtnV2 = document.getElementById("closeBtn_V2");

// Open modal
openBtnV2.addEventListener("click", function() {
     modalV2.style.display = "block";
});

// Close modal
closeBtnV2.addEventListener("click", function() {
     modalV2.style.display = "none";
});

// Close when clicking outside
window.addEventListener("click", function(e) {
     if (e.target === modalV2) {
          modalV2.style.display = "none";
     }
});
