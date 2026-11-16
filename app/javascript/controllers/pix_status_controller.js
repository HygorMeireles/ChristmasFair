import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.poll()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (response.ok) {
        const data = await response.json()
        if (data.redirect_url) {
          window.location.assign(data.redirect_url)
          return
        }
        if (["failed", "cancelled", "expired"].includes(data.status)) {
          if (!this.terminalStatus) {
            this.terminalStatus = data.status
            window.location.reload()
          }
          return
        }
      }
    } catch (_error) {
      // A próxima consulta tenta novamente após uma falha temporária de rede.
    }

    this.timer = setTimeout(() => this.poll(), 3000)
  }
}
