import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["closeButton"]

  connect() {
    console.debug("Close modal controller connected")
  }

  initialize() {
    this.closeButtonTargets.forEach(button => {
      button.addEventListener('click', this.closeModal.bind(this))
    })
  }

  closeModal(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.remove()
  }
}
