import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.debug("Close modal controller connected")
  }

  initialize() {
    this.element.addEventListener("click", this.closeModal.bind(this))
  }

  closeModal(event) {
    event.preventDefault()
    const modal = document.getElementById('modal')
    if (modal) {
      modal.remove()
    }
  }
}
