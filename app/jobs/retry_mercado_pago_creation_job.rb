class RetryMercadoPagoCreationJob < ApplicationJob
  queue_as :default

  retry_on MercadoPago::OrdersClient::NetworkError, wait: :polynomially_longer, attempts: 5

  def perform(payment_attempt_id)
    attempt = PaymentAttempt.find(payment_attempt_id)
    return unless attempt.status == "unknown"

    response = MercadoPago::OrdersClient.new.create_order(attempt)
    Checkout::AttachPixProviderOrder.call(attempt:, response:)
  rescue Checkout::AttachPixProviderOrder::InvalidResponse, MercadoPago::OrdersClient::ApiError => error
    attempt.update!(error_message: error.message)
    raise
  end
end
