class StockMovementsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    amount = Integer(params[:amount], exception: false)
    removing = params[:stock_action] == "remove" || params[:direction] == "remove"
    direction = removing ? -1 : 1
    movement_type = params[:movement_type].presence || (removing ? "loss" : "restock")

    Inventory::AdjustStock.call(
      product:,
      quantity_delta: amount.to_i * direction,
      movement_type:,
      note: params[:note]
    )
    redirect_to products_path, notice: t("inventory.updated")
  rescue Inventory::AdjustStock::InvalidAdjustment, ActiveRecord::RecordInvalid => error
    redirect_to products_path, alert: error.message
  end
end
