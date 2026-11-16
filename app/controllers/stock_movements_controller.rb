class StockMovementsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    amount = Integer(params[:amount], exception: false)
    direction = params[:direction] == "remove" ? -1 : 1

    Inventory::AdjustStock.call(
      product:,
      quantity_delta: amount.to_i * direction,
      movement_type: params[:movement_type],
      note: params[:note]
    )
    redirect_to products_path, notice: t("inventory.updated")
  rescue Inventory::AdjustStock::InvalidAdjustment, ActiveRecord::RecordInvalid => error
    redirect_to products_path, alert: error.message
  end
end
