class CashCheckoutsController < ApplicationController
  def create
    order = Checkout::CompleteCashSale.call(
      quantities: checkout_params.fetch(:quantities, {}),
      amount_received_brl: checkout_params[:amount_received_brl],
      checkout_token: checkout_params[:checkout_token]
    )

    redirect_to root_path,
      notice: t("checkout.completed", number: order.number, change: helpers.money(order.change_cents))
  rescue Checkout::CompleteCashSale::InvalidSale, ActiveRecord::RecordInvalid => error
    redirect_to root_path, alert: error.message
  end

  private

  def checkout_params
    params.require(:checkout).permit(:amount_received_brl, :checkout_token, quantities: Product::CODES)
  end
end
