import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "showIcon", "hideIcon"]

  toggle() {
    const visible = this.inputTarget.type === "text"

    this.inputTarget.type = visible ? "password" : "text"
    this.showIconTarget.classList.toggle("hidden", !visible)
    this.hideIconTarget.classList.toggle("hidden", visible)
    this.buttonTarget.setAttribute("aria-label", visible ? "Mostrar senha" : "Ocultar senha")
    this.buttonTarget.setAttribute("title", visible ? "Mostrar senha" : "Ocultar senha")
    this.buttonTarget.setAttribute("aria-pressed", (!visible).toString())
  }
}
