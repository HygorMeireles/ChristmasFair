class DashboardController < ApplicationController
  def index
    @products = Product.active.display_order
    @checkout_token = SecureRandom.uuid
    @payment_result = params[:payment].presence_in(%w[approved failed expired cancelled])
  end
end
