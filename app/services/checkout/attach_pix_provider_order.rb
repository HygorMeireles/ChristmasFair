module Checkout
  class AttachPixProviderOrder
    class InvalidResponse < StandardError; end

    def self.call(attempt:, response:)
      payment = response.dig("transactions", "payments", 0) || {}
      qr_data = response.dig("type_response", "qr_data")
      raise InvalidResponse, I18n.t("pix.missing_qr") if qr_data.blank? || response["id"].blank?

      attempt.update!(
        status: "pending",
        external_order_id: response.fetch("id"),
        external_payment_id: payment["id"],
        qr_data:,
        raw_response: response,
        error_message: nil
      )
      attempt
    end
  end
end
