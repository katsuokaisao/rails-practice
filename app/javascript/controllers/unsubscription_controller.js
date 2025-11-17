import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submitButton"]

  connect() {
    console.debug("Unsubscription controller connected")
    this.updateSubmitButton()
  }

  selectAll(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true
    })
    this.updateSubmitButton()
  }

  deselectAll(event) {
    event.preventDefault()
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateSubmitButton()
  }

  updateSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      const hasChecked = this.checkboxTargets.some(checkbox => checkbox.checked)
      this.submitButtonTarget.disabled = !hasChecked
    }
  }

  confirmSubmit(event) {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount === 0) {
      event.preventDefault()
      return
    }

    const message = this.element.dataset.confirmMessage ||
      `${checkedCount}個のテナントから退会します。よろしいですか？`

    if (!confirm(message)) {
      event.preventDefault()
    }
  }
}
