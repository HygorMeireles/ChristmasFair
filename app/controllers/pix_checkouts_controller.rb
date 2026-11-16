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

    status = attempt.reload.status
    render json: {
      status:,
      order_status: attempt.order.reload.status,
      redirect_url: payment_result_path(status)
    }
  end

  def destroy
    attempt = find_attempt
    order = Checkout::CancelPixOrder.call(attempt:)
    message = order.paid? ? t("pix.already_paid") : t("pix.cancelled")
    redirect_to root_path, notice: message
  rescue Checkout::CancelPixOrder::InvalidCancellation => error
    redirect_to pix_checkout_path(params[:token]), alert: error.message
  end

  private

  def checkout_params
    params.require(:checkout).permit(:checkout_token, quantities: Product::CODES)
  end

  def find_attempt
    PaymentAttempt.includes(order: :order_items).find_by!(public_token: params[:token])
  end

  def payment_result_path(status)
    return root_path(payment: "approved") if status == "approved"
    return root_path(payment: status) if status.in?(%w[failed expired cancelled])

    nil
  end
end
