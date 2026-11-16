class StockBatchesController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    Inventory::CreateStockBatch.call(
      product:,
      description: batch_params[:description],
      quantity: batch_params[:quantity],
      total_cost_brl: batch_params[:total_cost_brl],
      received_on: batch_params[:received_on],
      register_expense: batch_params[:register_expense]
    )

    redirect_to products_path, notice: t("stock_batches.created")
  rescue Inventory::CreateStockBatch::InvalidBatch, ActiveRecord::RecordInvalid => error
    redirect_to products_path, alert: error.message
  end

  private

  def batch_params
    params.require(:stock_batch).permit(:description, :quantity, :total_cost_brl, :received_on, :register_expense)
  end
end
