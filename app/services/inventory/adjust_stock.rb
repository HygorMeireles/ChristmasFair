module Inventory
  class AdjustStock
    class InvalidAdjustment < StandardError; end

    def self.call(product:, quantity_delta:, movement_type:, note: nil)
      new(product:, quantity_delta:, movement_type:, note:).call
    end

    def initialize(product:, quantity_delta:, movement_type:, note:)
      @product = product
      @quantity_delta = Integer(quantity_delta)
      @movement_type = movement_type
      @note = note
    rescue ArgumentError, TypeError
      raise InvalidAdjustment, I18n.t("inventory.invalid_quantity")
    end

    def call
      raise InvalidAdjustment, I18n.t("inventory.zero_quantity") if quantity_delta.zero?
      raise InvalidAdjustment, I18n.t("inventory.invalid_type") unless StockMovement::TYPES.include?(movement_type)

      Product.transaction do
        product.lock!
        new_stock = product.stock_quantity + quantity_delta
        raise InvalidAdjustment, I18n.t("inventory.insufficient_stock") if new_stock.negative?

        if product.hot_chocolate? && product.capacity_quantity.positive? && new_stock > product.capacity_quantity
          raise InvalidAdjustment, I18n.t("inventory.over_capacity")
        end

        product.update!(stock_quantity: new_stock)
        product.stock_movements.create!(
          movement_type:,
          quantity_delta:,
          stock_after: new_stock,
          note: note.presence
        )
      end

      product
    end

    private

    attr_reader :product, :quantity_delta, :movement_type, :note
  end
end
