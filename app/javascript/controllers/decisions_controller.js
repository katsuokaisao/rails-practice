import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suspensionPeriod", "suspensionUntilInput", "modal"]

  connect() {
    console.debug("Decisions controller connected")
  }

  toggleFields(event) {
    const selectedValue = event.target.value

    if (selectedValue === 'suspend_user') {
      this.suspensionPeriodTarget.style.display = 'block'
    } else {
      this.suspensionPeriodTarget.style.display = 'none'
    }
  }

  setDuration(event) {
    event.preventDefault()
    const days = event.currentTarget.dataset.days
    const date = new Date()
    date.setDate(date.getDate() + parseInt(days))

    const formattedDate = date.toISOString().slice(0, 16)

    this.suspensionUntilInputTarget.value = formattedDate
  }

  handleSubmit(event) {
    if (event.detail.success) {
      this.modalTarget.remove()
    }
  }
}
