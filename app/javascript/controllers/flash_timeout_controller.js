import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.hideTimer = window.setTimeout(() => this.hide(), 2000)
  }

  disconnect() {
    window.clearTimeout(this.hideTimer)
    window.clearTimeout(this.removeTimer)
  }

  hide() {
    if (this.removing) return

    this.removing = true
    this.element.style.opacity = "0"
    this.element.style.pointerEvents = "none"
    this.removeTimer = window.setTimeout(() => this.element.remove(), 200)
  }

  dismiss() {
    window.clearTimeout(this.hideTimer)
    this.hide()
  }
}
