// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
document.addEventListener('DOMContentLoaded', function() {
  const userMenuTrigger = document.querySelector('.user-menu-trigger');
  const userMenu = document.querySelector('.user-menu');

  if (userMenuTrigger && userMenu) {
    userMenuTrigger.addEventListener('click', function(e) {
      e.preventDefault();
      userMenu.classList.toggle('show');
    });

    document.addEventListener('click', function(e) {
      if (!userMenuTrigger.contains(e.target) && !userMenu.contains(e.target)) {
        userMenu.classList.remove('show');
      }
    });
  }
});
import "@hotwired/turbo-rails"
import "controllers"
