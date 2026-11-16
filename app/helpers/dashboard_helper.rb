module DashboardHelper
  def stock_label(product, quantity = product.stock_quantity)
    if product.stock_unit == "ml"
      number_to_human(quantity, units: { unit: "ml", thousand: "L" }, precision: 3, strip_insignificant_zeros: true)
    else
      t("dashboard.units", count: quantity)
    end
  end
end
