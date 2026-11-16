class PixCheckoutsController < ApplicationController
  def create
    attempt = Checkout::CreatePixOrder.call(
      quantities: checkout_params.fetch(:quantities, {}),
      checkout_token: checkout_params[:checkout_token]
    )
    redirect_to pix_checkout_path(attempt.public_token)
  rescue Checkout::CreatePixOrder::InvalidSale, ActiveRecord::RecordInvalid => error
    redirect_to root_path, alert: error.message
  end

  def show
    @attempt = find_attempt
    @order = @attempt.order
  end

  def status
    attempt = find_attempt
    if attempt.pending? && attempt.updated_at < 3.seconds.ago
      if attempt.external_order_id.present?
        ProcessMercadoPagoOrderJob.perform_later(attempt.external_order_id)
      elsif attempt.status == "unknown"
        RetryMercadoPagoCreationJob.perform_later(attempt.id)
      end
    end

    render json: {
      status: attempt.reload.status,
      order_status: attempt.order.reload.status,
      redirect_url: attempt.approved? ? root_path(payment: "approved") : nil
    }
  end

  private

  def checkout_params
    params.require(:checkout).permit(:checkout_token, quantities: Product::CODES)
  end

  def find_attempt
    PaymentAttempt.includes(order: :order_items).find_by!(public_token: params[:token])
  end
end
