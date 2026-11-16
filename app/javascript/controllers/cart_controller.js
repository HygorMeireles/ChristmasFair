import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["product", "quantity", "phone", "lockState", "readyState", "cartLines", "total", "quantityInput", "cashReceived", "change", "cashHint", "checkoutButton"]
  static values = { locale: String, currency: String }

  connect() {
    this.cart = new Map()
    this.totalCents = 0
    this.itemCount = 0
    this.render()
  }

  add(event) {
    const product = this.productFor(event.currentTarget.dataset.code)
    if (!product) return

    const current = this.cart.get(product.code) || 0
    if (current >= product.available) {
      this.pulse(product.element)
      return
    }

    this.cart.set(product.code, current + 1)
    this.render()
  }

  remove(event) {
    const code = event.currentTarget.dataset.code
    const current = this.cart.get(code) || 0
    if (current <= 1) this.cart.delete(code)
    else this.cart.set(code, current - 1)
    this.render()
  }

  clear() {
    this.cart.clear()
    this.cashReceivedTarget.value = ""
    this.render()
  }

  cashChanged() {
    this.updateCashState()
  }

  submitCash(event) {
    if (this.checkoutButtonTarget.disabled) {
      event.preventDefault()
      return
    }

    this.checkoutButtonTarget.disabled = true
    this.checkoutButtonTarget.value = this.checkoutButtonTarget.dataset.submittingLabel
  }

  render() {
    let total = 0
    let itemCount = 0
    this.cartLinesTarget.replaceChildren()

    this.productTargets.forEach((element) => {
      const product = this.readProduct(element)
      const quantity = this.cart.get(product.code) || 0
      const projectedStock = product.stock - (quantity * product.serving)
      total += product.price * quantity
      itemCount += quantity

      this.quantityTargets.filter((target) => target.dataset.code === product.code).forEach((target) => { target.value = quantity; target.textContent = quantity })
      this.renderProductStock(product, projectedStock, quantity)

      if (quantity > 0) this.appendLine(product, quantity)
    })

    this.totalCents = total
    this.itemCount = itemCount
    this.quantityInputTargets.forEach((input) => { input.value = this.cart.get(input.dataset.code) || 0 })

    const unlocked = itemCount > 0
    this.phoneTarget.classList.toggle("is-locked", !unlocked)
    this.lockStateTarget.hidden = unlocked
    this.readyStateTarget.hidden = !unlocked
    this.totalTarget.textContent = this.money(total)
    this.updateCashState()
  }

  updateCashState() {
    const normalized = this.cashReceivedTarget.value.replace(",", ".")
    const receivedCents = Math.round((Number(normalized) || 0) * 100)
    const enough = this.itemCount > 0 && receivedCents >= this.totalCents
    const change = enough ? receivedCents - this.totalCents : 0

    this.changeTarget.textContent = this.money(change)
    this.checkoutButtonTarget.disabled = !enough
    this.cashHintTarget.textContent = enough ? this.cashHintTarget.dataset.ready : this.cashHintTarget.dataset.waiting
    this.cashHintTarget.classList.toggle("is-ready", enough)
  }

  renderProductStock(product, projectedStock, quantity) {
    product.element.classList.toggle("has-selection", quantity > 0)
    const fill = product.element.querySelector("[data-cart-fill]")
    if (fill) {
      const percentage = product.capacity > 0 ? Math.max(0, Math.min(100, projectedStock / product.capacity * 100)) : 0
      fill.style.height = `${percentage}%`
    }

    const pieces = [...product.element.querySelectorAll(".stock-piece")]
    const projectedServings = Math.floor(projectedStock / product.serving)
    pieces.forEach((piece, index) => piece.classList.toggle("is-reserved", index >= projectedServings))

    const stockLabel = product.element.querySelector("[data-cart-stock-label]")
    if (stockLabel) stockLabel.textContent = product.unit === "ml" ? this.volume(projectedStock) : this.units(projectedStock)
  }

  appendLine(product, quantity) {
    const row = document.createElement("div")
    const label = document.createElement("span")
    const price = document.createElement("strong")
    label.textContent = `${quantity}× ${product.name}`
    price.textContent = this.money(product.price * quantity)
    row.append(label, price)
    this.cartLinesTarget.append(row)
  }

  productFor(code) {
    const element = this.productTargets.find((candidate) => candidate.dataset.code === code)
    return element ? this.readProduct(element) : null
  }

  readProduct(element) {
    return {
      element,
      code: element.dataset.code,
      name: element.dataset.name,
      price: Number(element.dataset.price),
      stock: Number(element.dataset.stock),
      capacity: Number(element.dataset.capacity),
      serving: Number(element.dataset.serving),
      available: Number(element.dataset.available),
      unit: element.dataset.code === "hot_chocolate" ? "ml" : "unit"
    }
  }

  money(cents) {
    return new Intl.NumberFormat(this.localeValue, { style: "currency", currency: this.currencyValue }).format(cents / 100)
  }

  volume(amount) {
    if (amount >= 1000) return `${new Intl.NumberFormat(this.localeValue, { maximumFractionDigits: 3 }).format(amount / 1000)} L`
    return `${amount} ml`
  }

  units(amount) {
    if (this.localeValue === "en") return `${amount} ${amount === 1 ? "unit" : "units"}`
    return `${amount} ${amount === 1 ? "unidade" : "unidades"}`
  }

  pulse(element) {
    element.classList.remove("limit-pulse")
    void element.offsetWidth
    element.classList.add("limit-pulse")
  }
}
