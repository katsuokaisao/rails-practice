import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.classList.add('fade-out');
      setTimeout(() => {
        this.element.remove();
      }, 500);
    }, 5000);
  }

  close() {
    this.element.remove();
  }
}
