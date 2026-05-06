import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.value = this.clean(this.element.value)
  }

  sanitize() {
    this.element.value = this.clean(this.element.value)
  }

  complete() {
    if (/^\d$/.test(this.element.value)) {
      this.element.value = `0${this.element.value}:00`
    } else if (/^([01]\d|2[0-3])$/.test(this.element.value)) {
      this.element.value = `${this.element.value}:00`
    } else if (/^([01]\d|2[0-3]):$/.test(this.element.value)) {
      this.element.value = `${this.element.value}00`
    } else if (/^([01]\d|2[0-3]):[0-5]$/.test(this.element.value)) {
      this.element.value = `${this.element.value}0`
    }
  }

  clean(value) {
    const digits = value.replace(/\D/g, "").slice(0, 4)

    if (digits.length === 0) return ""
    if (digits.length === 1 && Number(digits[0]) <= 2) return digits

    const [hour, minuteDigits] = this.splitDigits(digits)

    if (!hour) return ""
    if (minuteDigits.length === 0) return hour
    if (Number(minuteDigits[0]) > 5) return hour

    return `${hour}:${minuteDigits.slice(0, 2)}`
  }

  splitDigits(digits) {
    if (Number(digits[0]) > 2) {
      return [`0${digits[0]}`, digits.slice(1)]
    }

    const hour = digits.slice(0, 2)
    if (Number(hour) > 23) return ["", ""]

    return [hour, digits.slice(2)]
  }
}
