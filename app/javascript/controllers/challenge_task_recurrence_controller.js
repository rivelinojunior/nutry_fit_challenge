import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recurrenceType", "weekdays", "specificDate"]

  connect() {
    this.update()
  }

  update() {
    this.toggleField(this.weekdaysTarget, this.recurrenceTypeTarget.value !== "weekdays")
    this.toggleField(this.specificDateTarget, this.recurrenceTypeTarget.value !== "specific_date")
  }

  toggleField(field, hidden) {
    field.classList.toggle("hidden", hidden)
    field.querySelectorAll("input, select, textarea").forEach((input) => {
      input.disabled = hidden
    })
  }
}
