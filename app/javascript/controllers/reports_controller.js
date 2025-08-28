import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateUrl(event) {
    const targetType = event.currentTarget.dataset.targetType
    const url = new URL(window.location)
    url.searchParams.set('target_type', targetType)
    window.history.pushState({}, '', url)
  }
}
