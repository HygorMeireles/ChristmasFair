module Checkout
  class ConfirmPixSale
    class InvalidConfirmation < StandardError; end

    def self.call(attempt:, provider_data:)
      new(attempt:, provider_data:).call
    end

    def initialize(attempt:, provider_data:)
      @attempt = attempt
      @provider_data = provider_data
    end

    def call
      validate_provider_data!

      Order.transaction do
        attempt.lock!
        order = attempt.order
        order.lock!
        return order if order.paid?

        items = order.order_items.includes(:stock_reservation).order(:product_id)
        products = Product.where(id: items.map(&:product_id)).order(:id).lock.index_by(&:id)
        items.each do |item|
          product = products.fetch(item.product_id)
          reservation = item.stock_reservation
          raise InvalidConfirmation, I18n.t("pix.missing_reservation") unless reservation&.status == "reserved"
          raise InvalidConfirmation, I18n.t("checkout.insufficient_stock", product: product.localized_name) if reservation.quantity > product.stock_quantity

          new_stock = product.stock_quantity - reservation.quantity
          item.quantity.times { item.fishing_tickets.create! } if product.code == "fishing"
          Inventory::AllocateCost.call(order_item: item, quantity: reservation.quantity)
          product.update!(stock_quantity: new_stock)
          product.stock_movements.create!(
            movement_type: "sale",
            quantity_delta: -reservation.quantity,
            stock_after: new_stock,
            note: I18n.t("checkout.stock_note", number: order.number)
          )
          reservation.update!(status: "confirmed")
        end

        fee_basis_points = EventSetting.current.mercado_pago_fee_basis_points
        fee_cents = (order.total_cents * fee_basis_points / 10_000.0).round
        order.update!(
          status: "paid",
          amount_received_cents: order.total_cents,
          change_cents: 0,
          provider_fee_basis_points: fee_basis_points,
          provider_fee_cents: fee_cents,
          paid_at: Time.current
        )
        attempt.update!(status: "approved", raw_response: provider_data, error_message: nil)
        order
      end
    end

    private

    attr_reader :attempt, :provider_data

    def validate_provider_data!
      raise InvalidConfirmation, I18n.t("pix.wrong_provider_order") unless provider_data["id"] == attempt.external_order_id
      raise InvalidConfirmation, I18n.t("pix.wrong_reference") unless provider_data["external_reference"] == "christmas_fair_order_#{attempt.order_id}"
      raise InvalidConfirmation, I18n.t("pix.not_approved") unless provider_data["status"] == "processed" && provider_data["status_detail"] == "accredited"

      received_cents = (BigDecimal(provider_data["total_amount"].to_s) * 100).round
      raise InvalidConfirmation, I18n.t("pix.wrong_amount") unless received_cents == attempt.order.total_cents
    rescue ArgumentError
      raise InvalidConfirmation, I18n.t("pix.wrong_amount")
    end
  end
end
