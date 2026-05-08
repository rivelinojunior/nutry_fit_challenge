import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog" ]
  static values = {
    dismissedKey: { type: String, default: "nutryfit:pwa-install-prompt-dismissed:v1" }
  }

  connect() {
    this.installPromptEvent = null
    this.boundBeforeInstallPrompt = (event) => this.preparePrompt(event)
    this.boundAppInstalled = () => this.rememberDismissed()

    window.addEventListener("beforeinstallprompt", this.boundBeforeInstallPrompt)
    window.addEventListener("appinstalled", this.boundAppInstalled)
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.boundBeforeInstallPrompt)
    window.removeEventListener("appinstalled", this.boundAppInstalled)
  }

  preparePrompt(event) {
    event.preventDefault()

    if (this.dismissed || this.runningStandalone) return

    this.installPromptEvent = event
    this.open()
  }

  async install() {
    if (!this.installPromptEvent) return

    const event = this.installPromptEvent
    this.installPromptEvent = null

    event.prompt()

    if (event.userChoice) {
      await event.userChoice
    }

    this.rememberDismissed()
    this.close()
  }

  dismiss() {
    this.rememberDismissed()
    this.close()
  }

  dismissFromDialog() {
    this.rememberDismissed()
  }

  open() {
    if (!this.hasDialogTarget || this.dialogTarget.open) return

    this.dialogTarget.showModal()
  }

  close() {
    if (!this.hasDialogTarget || !this.dialogTarget.open) return

    this.dialogTarget.close()
  }

  rememberDismissed() {
    this.installPromptEvent = null

    try {
      window.localStorage.setItem(this.dismissedKeyValue, "true")
    } catch {
      this.dismissedInMemory = true
    }
  }

  get dismissed() {
    if (this.dismissedInMemory) return true

    try {
      return window.localStorage.getItem(this.dismissedKeyValue) === "true"
    } catch {
      return false
    }
  }

  get runningStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }
}
