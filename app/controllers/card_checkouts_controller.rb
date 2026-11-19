class CardCheckoutsController < ApplicationController
  def create
    Checkout::CompleteCardSale.call(
      quantities: checkout_params.fetch(:quantities, {}),
      payment_method: checkout_params[:payment_method],
      checkout_token: checkout_params[:checkout_token]
    )

    redirect_to root_path(payment: "card_approved")
  rescue Checkout::CompleteCardSale::InvalidSale, ActiveRecord::RecordInvalid => error
    redirect_to root_path, alert: error.message
  end

  private

  def checkout_params
    params.require(:checkout).permit(:payment_method, :checkout_token, quantities: Product::CODES)
  end
end
