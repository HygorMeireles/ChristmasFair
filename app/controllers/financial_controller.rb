class FinancialController < ApplicationController
  def index
    paid_orders = Order.where(status: "paid")
    @gross_sales_cents = paid_orders.sum(:total_cents)
    @cash_sales_cents = paid_orders.where(payment_method: "cash").sum(:total_cents)
    @paid_expenses_cents = Expense.paid.sum(:amount_cents)
    @pending_expenses_cents = Expense.pending.sum(:amount_cents)
    @cash_result_cents = @cash_sales_cents - @paid_expenses_cents
    costed_items = OrderItem.joins(:order).where(orders: { status: "paid" }, cost_complete: true)
    @costed_revenue_cents = costed_items.sum(:line_total_cents)
    @cost_of_goods_cents = costed_items.sum(:cost_cents)
    @gross_margin_cents = @costed_revenue_cents - @cost_of_goods_cents
    @uncosted_items_count = OrderItem.joins(:order).where(orders: { status: "paid" }, cost_complete: false).sum(:quantity)
    @sales_by_product = sales_by_product
    @recent_orders = paid_orders.includes(:order_items).order(paid_at: :desc).limit(10)
    @expenses = Expense.recent_first
    @expense = Expense.new(incurred_on: Date.current, status: "paid", paid_on: Date.current)
  end

  private

  def sales_by_product
    totals = OrderItem.joins(:order)
      .where(orders: { status: "paid" })
      .group(:product_code)
      .pluck(:product_code, Arel.sql("SUM(quantity)"), Arel.sql("SUM(line_total_cents)"))

    products = Product.where(code: totals.map(&:first)).index_by(&:code)
    totals.map do |code, quantity, revenue_cents|
      { code:, quantity:, revenue_cents:, product: products[code] }
    end
  end
end
