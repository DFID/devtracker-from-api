// Add JavaScript here

// Homepage banner
const btn = document.getElementById("read_more");
const div = document.getElementById("read_more_content");

btn.addEventListener("click", function() {
     div.classList.toggle("active");

// Change button text
     if (div.classList.contains("active")) {
          this.textContent = "Close";
     } else {
          this.textContent = "Read more";
     }
});

