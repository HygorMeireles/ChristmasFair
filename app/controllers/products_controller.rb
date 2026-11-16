class ProductsController < ApplicationController
  def index
    @products = Product.display_order.includes(:stock_movements)
  end

  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      redirect_to products_path, notice: t("products.updated")
    else
      @products = Product.display_order.includes(:stock_movements)
      flash.now[:alert] = @product.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.require(:product).permit(:name_pt, :name_en, :price_brl, :capacity_quantity, :serving_size, :active)
  end
end
