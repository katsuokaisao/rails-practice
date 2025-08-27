// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "controllers"

// function initDropdown() {
//   const dropdownTrigger = document.querySelector('.dropdown-trigger');
//   const dropdownMenu = document.querySelector('.dropdown-menu');

//   if (dropdownTrigger && dropdownMenu) {
//     dropdownTrigger.addEventListener('click', function(e) {
//       e.preventDefault();
//       dropdownMenu.classList.toggle('show');
//     });

//     document.addEventListener('click', function(e) {
//       if (!dropdownTrigger.contains(e.target) && !dropdownMenu.contains(e.target)) {
//         dropdownMenu.classList.remove('show');
//       }
//     });
//   }
// }

// document.addEventListener('turbo:load', initDropdown);
// document.addEventListener('DOMContentLoaded', initDropdown);
