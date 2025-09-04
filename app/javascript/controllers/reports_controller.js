import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateUrl(event) {
    event.preventDefault()
    const targetType = event.currentTarget.href.includes('target_type=user') ? 'user' : 'comment'
    const url = new URL(window.location)
    url.searchParams.set('target_type', targetType)
    window.location.href = url.toString()
  }
}
