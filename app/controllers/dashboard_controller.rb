class DashboardController < ApplicationController
  def index
    @products = Product.active.display_order
    @checkout_token = SecureRandom.uuid
  end
end
