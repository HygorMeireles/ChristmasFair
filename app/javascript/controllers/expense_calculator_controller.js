import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "unitAmount", "discount", "total"]

  connect() {
    this.calculate()
  }

  calculate() {
    const quantity = Math.max(Number.parseInt(this.quantityTarget.value || "0", 10), 0)
    const unitAmount = this.currencyValue(this.unitAmountTarget.value)
    const discount = this.currencyValue(this.discountTarget.value)
    const total = Math.max((quantity * unitAmount) - discount, 0)
    this.totalTarget.textContent = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(total / 100)
  }

  currencyValue(value) {
    const normalized = String(value || "").trim().replace(/\s/g, "").replace(",", ".")
    const number = Number.parseFloat(normalized)
    return Number.isFinite(number) ? Math.round(number * 100) : 0
  }
}
