module Checkout
  class CompleteCashSale
    class InvalidSale < StandardError; end

    def self.call(quantities:, amount_received_brl:, checkout_token:)
      new(quantities:, amount_received_brl:, checkout_token:).call
    end

    def initialize(quantities:, amount_received_brl:, checkout_token:)
      @raw_quantities = quantities.to_h.stringify_keys
      @amount_received_brl = amount_received_brl
      @checkout_token = checkout_token.to_s
    end

    def call
      validate_checkout_token!
      existing_order = Order.find_by(checkout_token:)
      return existing_order if existing_order

      Order.transaction do
        products = locked_products
        total_cents = calculate_total(products)
        amount_received_cents = parse_money(amount_received_brl)
        raise InvalidSale, I18n.t("checkout.insufficient_payment") if amount_received_cents < total_cents

        order = Order.create!(
          checkout_token:,
          status: "paid",
          payment_method: "cash",
          total_cents:,
          amount_received_cents:,
          change_cents: amount_received_cents - total_cents,
          paid_at: Time.current
        )

        products.each do |product|
          quantity = quantities.fetch(product.code)
          stock_delta = -(quantity * product.serving_size)
          new_stock = product.stock_quantity + stock_delta

          order_item = order.order_items.create!(
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
          quantity.times { order_item.fishing_tickets.create! } if product.code == "fishing"
          Inventory::AllocateCost.call(order_item:, quantity: -stock_delta)
          product.update!(stock_quantity: new_stock)
          product.stock_movements.create!(
            movement_type: "sale",
            quantity_delta: stock_delta,
            stock_after: new_stock,
            note: I18n.t("checkout.stock_note", number: order.number)
          )
        end

        order
      end
    rescue ActiveRecord::RecordNotUnique
      Order.find_by!(checkout_token:)
    end

    private

    attr_reader :raw_quantities, :amount_received_brl, :checkout_token

    def quantities
      @quantities ||= raw_quantities.each_with_object({}) do |(code, value), result|
        parsed = Integer(value, exception: false)
        raise InvalidSale, I18n.t("checkout.invalid_quantity") if parsed.nil? || parsed.negative?

        result[code] = parsed if parsed.positive?
      end
    end

    def validate_checkout_token!
      raise InvalidSale, I18n.t("checkout.invalid_request") unless checkout_token.match?(/\A[0-9a-f-]{36}\z/i)
      raise InvalidSale, I18n.t("checkout.empty_cart") if quantities.empty?
    end

    def locked_products
      products = Product.active.where(code: quantities.keys).order(:id).lock.to_a
      raise InvalidSale, I18n.t("checkout.unavailable_product") unless products.size == quantities.size

      reserved = StockReservation.active.where(product_id: products.map(&:id)).group(:product_id).sum(:quantity)
      products.each do |product|
        requested_stock = quantities.fetch(product.code) * product.serving_size
        available_stock = product.stock_quantity - reserved.fetch(product.id, 0)
        raise InvalidSale, I18n.t("checkout.insufficient_stock", product: product.localized_name) if requested_stock > available_stock
      end
      products
    end

    def calculate_total(products)
      total = products.sum { |product| product.price_cents * quantities.fetch(product.code) }
      raise InvalidSale, I18n.t("checkout.invalid_total") unless total.positive?

      total
    end

    def parse_money(value)
      normalized = value.to_s.strip.gsub(/\s+/, "").tr(",", ".")
      cents = (BigDecimal(normalized) * 100).round
      raise ArgumentError if cents.negative?

      cents
    rescue ArgumentError
      raise InvalidSale, I18n.t("checkout.invalid_payment")
    end
  end
end
