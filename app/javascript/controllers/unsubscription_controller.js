import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submitButton"]

  connect() {
    this.updateSubmitButton()
  }

  selectAll(event) {
    event.preventDefault()
    this.toggleAllCheckboxes(true)
  }

  deselectAll(event) {
    event.preventDefault()
    this.toggleAllCheckboxes(false)
  }

  updateSubmitButton() {
    if (!this.hasSubmitButtonTarget) return

    const hasChecked = this.checkboxTargets.some(checkbox => checkbox.checked)
    this.submitButtonTarget.disabled = !hasChecked
  }

  confirmSubmit(event) {
    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount === 0) {
      event.preventDefault()
      alert("一つ以上のテナントを選択してください。")
      return
    }

    const message = this.element.dataset.confirmMessage ||
      `${checkedCount}個のテナントから退会します。よろしいですか？`

    if (!confirm(message)) {
      event.preventDefault()
    }
  }

  toggleAllCheckboxes(checked) {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = checked
    })
    this.updateSubmitButton()
  }
}
