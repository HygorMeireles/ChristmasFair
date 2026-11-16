module Checkout
  class ResolvePixOrder
    def self.call(attempt:, provider_data:)
      new(attempt:, provider_data:).call
    end

    def initialize(attempt:, provider_data:)
      @attempt = attempt
      @provider_data = provider_data
    end

    def call
      if provider_data["status"] == "processed" && provider_data["status_detail"] == "accredited"
        Checkout::ConfirmPixSale.call(attempt:, provider_data:)
      elsif provider_data["status"].in?(%w[canceled expired])
        release_reservations(provider_data["status"])
      else
        attempt.update!(status: "pending", raw_response: provider_data, error_message: nil)
      end
    end

    private

    attr_reader :attempt, :provider_data

    def release_reservations(status)
      Order.transaction do
        attempt.lock!
        return if attempt.order.paid?

        attempt.order.update!(status: "cancelled")
        attempt.update!(status: status == "expired" ? "expired" : "cancelled", raw_response: provider_data)
        attempt.order.order_items.each { |item| item.stock_reservation&.update!(status: "released") }
      end
    end
  end
end
