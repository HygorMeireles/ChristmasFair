require "net/http"
require "json"

module MercadoPago
  class OrdersClient
    class ConfigurationError < StandardError; end
    class ApiError < StandardError; end
    class NetworkError < StandardError; end

    API_URL = "https://api.mercadopago.com/v1/orders"

    def create_order(payment_attempt)
      order = payment_attempt.order
      response = request(
        Net::HTTP::Post,
        URI(API_URL),
        body: create_payload(order),
        idempotency_key: payment_attempt.idempotency_key
      )
      raise ApiError, error_message(response) unless response.code == "201"

      parse_json(response)
    end

    def fetch_order(external_order_id)
      response = request(Net::HTTP::Get, URI("#{API_URL}/#{external_order_id}"))
      raise ApiError, error_message(response) unless response.code == "200"

      parse_json(response)
    end

    def cancel_order(external_order_id, idempotency_key:)
      response = request(
        Net::HTTP::Post,
        URI("#{API_URL}/#{external_order_id}/cancel"),
        idempotency_key:
      )
      raise ApiError, error_message(response) unless response.code == "200"

      parse_json(response)
    end

    private

    def request(request_class, uri, body: nil, idempotency_key: nil)
      validate_configuration!
      request = request_class.new(uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json"
      request["X-Idempotency-Key"] = idempotency_key if idempotency_key
      request.body = JSON.generate(body) if body

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
    rescue Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => error
      raise NetworkError, I18n.t("pix.network_error", message: error.message)
    end

    def create_payload(order)
      amount = money(order.total_cents)
      {
        type: "qr",
        total_amount: amount,
        description: "Mister Wiz Christmas Fair - Pedido #{order.number}",
        external_reference: external_reference(order),
        expiration_time: "PT15M",
        config: { qr: { external_pos_id:, mode: "dynamic" } },
        transactions: { payments: [ { amount: } ] },
        items: order.order_items.map do |item|
          {
            title: item.product_name_pt,
            unit_price: money(item.unit_price_cents),
            unit_measure: "unit",
            external_code: item.product_code,
            quantity: item.quantity
          }
        end
      }
    end

    def external_reference(order)
      "christmas_fair_order_#{order.id}"
    end

    def money(cents)
      format("%.2f", cents.to_i / 100.0)
    end

    def parse_json(response)
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise ApiError, I18n.t("pix.invalid_response")
    end

    def error_message(response)
      body = parse_json(response)
      body["message"].presence || body.dig("errors", 0, "message").presence || "HTTP #{response.code}"
    rescue ApiError
      "HTTP #{response.code}"
    end

    def validate_configuration!
      return if access_token.present? && external_pos_id.present?

      raise ConfigurationError, I18n.t("pix.not_configured")
    end

    def access_token
      configuration_value("MERCADO_PAGO_ACCESS_TOKEN", :access_token)
    end

    def external_pos_id
      configuration_value("MERCADO_PAGO_EXTERNAL_POS_ID", :external_pos_id)
    end

    def configuration_value(environment_key, credential_key)
      return ENV[environment_key].presence if ENV.key?(environment_key)

      Rails.application.credentials.dig(:mercado_pago, credential_key)
    end
  end
end
