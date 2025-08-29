import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["suspensionPeriod"]

  connect() {
    console.debug("Decisions controller connected")
  }

  updateUrl(event) {
    const targetType = event.currentTarget.dataset.targetType
    const url = new URL(window.location)
    url.searchParams.set('target_type', targetType)
    window.history.pushState({}, '', url)
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

    this.element.querySelector('input[name="decision[suspension_until]"]').value = formattedDate
  }

  handleSubmit(event) {
    if (event.detail.success) {
      document.getElementById('decision-modal').remove()
    } else if (event.detail.error === 'concurrent_modification') {
      alert('他のモデレーターが既にこの通報を審査しました。ページをリロードしてください。')
      document.getElementById('decision-modal').remove()
      window.location.reload()
    }
  }
}
