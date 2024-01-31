// toggle search
function toggleGlobalSearch() {
    var toggleGlobalSearch = document.getElementById("toggleGlobalSearch")
    var toggleGlobalMenu = document.getElementById("toggleGlobalMenu");
    var globalMenu = document.getElementById("globalMenu");

    if (toggleGlobalMenu.classList.contains("app-header__menu-button--active")) {
        toggleGlobalMenu.classList.remove("app-header__menu-button--active")
        globalMenu.style.display = "none";
    }

    var globalSearch = document.getElementById("globalSearch");
    if (globalSearch.style.display === "block") {
        globalSearch.style.display = "none";
    } else {
        globalSearch.style.display = "block";
    }
    toggleGlobalSearch.classList.toggle("app-header__search-button--active");
}

// toggle main menu
function toggleGlobalMenu() {
    var toggleGlobalMenu = document.getElementById("toggleGlobalMenu");
    var toggleGlobalSearch = document.getElementById("toggleGlobalSearch");
    var globalSearch = document.getElementById("globalSearch");

    if (toggleGlobalSearch.classList.contains("app-header__search-button--active")) {
        toggleGlobalSearch.classList.remove("app-header__search-button--active")
        globalSearch.style.display = "none";
    }

    var globalMenu = document.getElementById("globalMenu");
    if (globalMenu.style.display === "block") {
        globalMenu.style.display = "none";
    } else {
        globalMenu.style.display = "block";
    }
    toggleGlobalMenu.classList.toggle("app-header__menu-button--active");
}

const modal = document.querySelector(".app-modal--advanced-filters");
const overlay = document.querySelector(".app-modal--overlay");
const openModalBtn = document.querySelector(".app-modal--open");
const closeModalBtn = document.querySelector(".app-modal--close");
const cancelModalBtn = document.querySelector(".app-modal--cancel");
const applyFiltersBtn = document.querySelector(".app-modal--apply");

// close modal function
const closeModal = function () {
    document.body.style.overflow = "auto"
    modal.classList.add("app-modal--hidden");
    overlay.classList.add("app-modal--hidden");
};

// close the modal when the close button is clicked
//closeModalBtn.addEventListener("click", closeModal);
//cancelModalBtn.addEventListener("click", closeModal);
//applyFiltersBtn.addEventListener("click", closeModal);
//overlay.addEventListener("click", closeModal);

// close modal when the Esc key is pressed
document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && !modal.classList.contains("hidden")) {
        closeModal();
    }
});

// open modal function
const openModal = function () {
    document.body.style.overflow = "hidden"
    modal.classList.remove("app-modal--hidden");
    //overlay.classList.remove("app-modal--hidden");
};

// open modal event
//openModalBtn.addEventListener("click", openModal);
