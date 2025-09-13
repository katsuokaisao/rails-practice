import { Controller } from "@hotwired/stimulus"
import { formatInTimeZone } from 'date-fns-tz'
import { addDays } from 'date-fns'

export default class extends Controller {
  static targets = ["suspensionPeriod", "suspensionUntilInput", "modal"]

  static values = {
    userTimeZoneIdentifier: String,
  }

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
    const days = parseInt(event.currentTarget.dataset.days, 10)
    const futureDate = addDays(new Date(), days)
    this.suspensionUntilInputTarget.value = formatInTimeZone(futureDate, this.userTimeZoneIdentifierValue, "yyyy-MM-dd'T'HH:mm")
  }

  handleSubmit(event) {
    if (event.detail.success) {
      this.modalTarget.remove()
    }
  }
}
