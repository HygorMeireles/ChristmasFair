class ProcessMercadoPagoOrderJob < ApplicationJob
  queue_as :default

  retry_on MercadoPago::OrdersClient::NetworkError, wait: :polynomially_longer, attempts: 5

  def perform(external_order_id, payment_event_id = nil)
    attempt = PaymentAttempt.find_by!(external_order_id:)
    provider_data = MercadoPago::OrdersClient.new.fetch_order(external_order_id)
    Checkout::ResolvePixOrder.call(attempt:, provider_data:)
    PaymentEvent.find_by(id: payment_event_id)&.update!(processed_at: Time.current, error_message: nil)
  rescue => error
    PaymentEvent.find_by(id: payment_event_id)&.update!(error_message: error.message)
    raise
  end
end
