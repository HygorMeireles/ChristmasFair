module Checkout
  class CancelPixOrder
    class InvalidCancellation < StandardError; end

    def self.call(attempt:, client: MercadoPago::OrdersClient.new)
      new(attempt:, client:).call
    end

    def initialize(attempt:, client:)
      @attempt = attempt
      @client = client
    end

    def call
      return attempt.order unless attempt.pending?
      raise InvalidCancellation, I18n.t("pix.cannot_cancel_recovering") if attempt.external_order_id.blank?

      attempt.update!(cancel_idempotency_key: SecureRandom.uuid) if attempt.cancel_idempotency_key.blank?
      provider_data = client.cancel_order(
        attempt.external_order_id,
        idempotency_key: attempt.cancel_idempotency_key
      )
      Checkout::ResolvePixOrder.call(attempt:, provider_data:)
      attempt.order
    rescue MercadoPago::OrdersClient::ApiError
      reconcile_after_conflict
    rescue MercadoPago::OrdersClient::ConfigurationError,
      MercadoPago::OrdersClient::NetworkError => error
      raise InvalidCancellation, error.message
    end

    private

    attr_reader :attempt, :client

    def reconcile_after_conflict
      provider_data = client.fetch_order(attempt.external_order_id)
      Checkout::ResolvePixOrder.call(attempt:, provider_data:)
      return attempt.order unless attempt.reload.pending?

      raise InvalidCancellation, I18n.t("pix.cannot_cancel")
    rescue MercadoPago::OrdersClient::ApiError,
      MercadoPago::OrdersClient::NetworkError => error
      raise InvalidCancellation, error.message
    end
  end
end
