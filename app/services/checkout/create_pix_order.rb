module Checkout
  class CreatePixOrder
    class InvalidSale < StandardError; end

    def self.call(quantities:, checkout_token:, client: MercadoPago::OrdersClient.new)
      new(quantities:, checkout_token:, client:).call
    end

    def initialize(quantities:, checkout_token:, client:)
      @raw_quantities = quantities.to_h.stringify_keys
      @checkout_token = checkout_token.to_s
      @client = client
    end

    def call
      validate_request!
      existing = Order.find_by(checkout_token:)&.payment_attempts&.first
      return existing if existing

      attempt = create_pending_records
      create_provider_order(attempt)
    end

    private

    attr_reader :raw_quantities, :checkout_token, :client

    def quantities
      @quantities ||= raw_quantities.each_with_object({}) do |(code, value), result|
        parsed = Integer(value, exception: false)
        raise InvalidSale, I18n.t("checkout.invalid_quantity") if parsed.nil? || parsed.negative?

        result[code] = parsed if parsed.positive?
      end
    end

    def validate_request!
      raise InvalidSale, I18n.t("checkout.invalid_request") unless checkout_token.match?(/\A[0-9a-f-]{36}\z/i)
      raise InvalidSale, I18n.t("checkout.empty_cart") if quantities.empty?
    end

    def create_pending_records
      Order.transaction do
        products = Product.active.where(code: quantities.keys).order(:id).lock.to_a
        raise InvalidSale, I18n.t("checkout.unavailable_product") unless products.size == quantities.size

        reserved = StockReservation.active.where(product_id: products.map(&:id)).group(:product_id).sum(:quantity)
        products.each do |product|
          requested = quantities.fetch(product.code) * product.serving_size
          available = product.stock_quantity - reserved.fetch(product.id, 0)
          raise InvalidSale, I18n.t("checkout.insufficient_stock", product: product.localized_name) if requested > available
        end

        total_cents = products.sum { |product| product.price_cents * quantities.fetch(product.code) }
        raise InvalidSale, I18n.t("checkout.invalid_total") unless total_cents.positive?

        order = Order.create!(
          checkout_token:,
          status: "pending",
          payment_method: "pix",
          total_cents:,
          amount_received_cents: 0,
          change_cents: 0
        )
        expires_at = 15.minutes.from_now
        products.each do |product|
          quantity = quantities.fetch(product.code)
          item = order.order_items.create!(
            product:,
            product_code: product.code,
            product_name_pt: product.name_pt,
            product_name_en: product.name_en,
            stock_unit: product.stock_unit,
            unit_price_cents: product.price_cents,
            quantity:,
            stock_quantity_per_item: product.serving_size,
            line_total_cents: product.price_cents * quantity
          )
          item.create_stock_reservation!(
            product:,
            quantity: quantity * product.serving_size,
            status: "reserved",
            expires_at:
          )
        end
        order.payment_attempts.create!(
          public_token: SecureRandom.urlsafe_base64(24),
          provider: "mercado_pago",
          status: "creating",
          idempotency_key: SecureRandom.uuid,
          expires_at:
        )
      end
    rescue ActiveRecord::RecordNotUnique
      Order.find_by!(checkout_token:).payment_attempts.first!
    end

    def create_provider_order(attempt)
      response = client.create_order(attempt)
      Checkout::AttachPixProviderOrder.call(attempt:, response:)
    rescue MercadoPago::OrdersClient::ConfigurationError,
      MercadoPago::OrdersClient::ApiError,
      Checkout::AttachPixProviderOrder::InvalidResponse => error
      cancel_local_attempt(attempt, error.message)
      raise InvalidSale, error.message
    rescue MercadoPago::OrdersClient::NetworkError => error
      attempt.update!(status: "unknown", error_message: error.message)
      attempt
    end

    def cancel_local_attempt(attempt, message)
      Order.transaction do
        attempt.lock!
        attempt.update!(status: "failed", error_message: message)
        attempt.order.update!(status: "cancelled")
        attempt.order.order_items.each { |item| item.stock_reservation&.update!(status: "released") }
      end
    end
  end
end
