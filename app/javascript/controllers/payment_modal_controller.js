import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (typeof this.element.showModal === "function" && !this.element.open) this.element.showModal()
  }

  close() {
    this.element.close()
    const url = new URL(window.location.href)
    url.searchParams.delete("payment")
    window.history.replaceState({}, "", url)
  }

  closeFromBackdrop(event) {
    if (event.target === this.element) this.close()
  }
}
