import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "toggleButton"]
  static values = { customer: Boolean, syncUrl: String }

  connect() {
    this.channel = new BroadcastChannel("christmas-fair-display-control")
    this.channel.onmessage = ({ data }) => this.receive(data)
    this.frozen = localStorage.getItem("christmas-fair-display-frozen") === "true"
    this.render()

    if (this.customerValue) this.channel.postMessage({ type: "display_ready" })
    else if (this.hasSyncUrlValue) this.broadcastNavigation()
  }

  disconnect() {
    this.channel?.close()
  }

  toggle() {
    this.frozen = !this.frozen
    localStorage.setItem("christmas-fair-display-frozen", String(this.frozen))
    this.channel.postMessage({ type: "freeze", frozen: this.frozen })
    this.render()
  }

  receive(data) {
    if (data.type === "freeze") {
      this.frozen = data.frozen
      localStorage.setItem("christmas-fair-display-frozen", String(this.frozen))
      this.render()
    }

    if (!this.customerValue && data.type === "display_ready" && this.hasSyncUrlValue) this.broadcastNavigation()

    if (this.customerValue && data.type === "navigate") {
      const target = new URL(data.url, window.location.origin)
      if (`${window.location.pathname}${window.location.search}` !== `${target.pathname}${target.search}`) window.location.assign(target)
    }
  }

  broadcastNavigation() {
    const target = new URL(this.syncUrlValue, window.location.origin)
    target.searchParams.set("customer_display", "1")
    this.channel.postMessage({ type: "navigate", url: `${target.pathname}${target.search}` })
  }

  render() {
    if (this.hasOverlayTarget) this.overlayTarget.hidden = !(this.customerValue && this.frozen)
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.textContent = this.frozen ? this.toggleButtonTarget.dataset.unfreezeLabel : this.toggleButtonTarget.dataset.freezeLabel
      this.toggleButtonTarget.classList.toggle("active", this.frozen)
    }
  }
}
