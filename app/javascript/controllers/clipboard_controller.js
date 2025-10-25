import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["icon", "successIcon"]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.showSuccess()

      setTimeout(() => {
        this.resetDefault()
      }, 1000)
    }).catch(err => {
      console.error('コピーに失敗しました:', err)
    })
  }

  showSuccess() {
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("hidden")
    }
    if (this.hasSuccessIconTarget) {
      this.successIconTarget.classList.remove("hidden")
    }
  }

  resetDefault() {
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("hidden")
    }
    if (this.hasSuccessIconTarget) {
      this.successIconTarget.classList.add("hidden")
    }
  }
}
