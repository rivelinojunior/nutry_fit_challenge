import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template", "row"]

  add(event) {
    event.preventDefault()

    this.listTarget.append(this.templateTarget.content.cloneNode(true))
  }

  remove(event) {
    event.preventDefault()

    if (this.rowTargets.length === 1) {
      this.clearRow(event.currentTarget.closest("[data-challenge-task-links-target='row']"))
      return
    }

    event.currentTarget.closest("[data-challenge-task-links-target='row']").remove()
  }

  clearRow(row) {
    row.querySelectorAll("input").forEach((input) => {
      input.value = ""
    })
  }
}
