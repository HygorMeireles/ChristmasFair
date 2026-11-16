class DashboardController < ApplicationController
  def index
    @products = Product.active.display_order
  end
end
