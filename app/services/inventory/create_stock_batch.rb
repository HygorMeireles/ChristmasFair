module Inventory
  class CreateStockBatch
    class InvalidBatch < StandardError; end

    def self.call(product:, description:, quantity:, total_cost_brl:, received_on:, register_expense:)
      new(product:, description:, quantity:, total_cost_brl:, received_on:, register_expense:).call
    end

    def initialize(product:, description:, quantity:, total_cost_brl:, received_on:, register_expense:)
      @product = product
      @description = description.to_s.strip
      @quantity = Integer(quantity, exception: false)
      @total_cost_cents = parse_money(total_cost_brl)
      @received_on = Date.parse(received_on.to_s)
      @register_expense = ActiveModel::Type::Boolean.new.cast(register_expense)
    rescue ArgumentError
      raise InvalidBatch, I18n.t("stock_batches.invalid_values")
    end

    def call
      raise InvalidBatch, I18n.t("stock_batches.invalid_values") if description.blank? || quantity.nil? || quantity <= 0 || total_cost_cents <= 0

      Product.transaction do
        product.lock!
        new_stock = product.stock_quantity + quantity
        if product.hot_chocolate? && product.capacity_quantity.positive? && new_stock > product.capacity_quantity
          raise InvalidBatch, I18n.t("inventory.over_capacity")
        end

        expense = create_expense if register_expense
        batch = product.stock_batches.create!(
          expense:,
          description:,
          initial_quantity: quantity,
          remaining_quantity: quantity,
          total_cost_cents:,
          allocated_cost_cents: 0,
          received_on:
        )
        product.update!(stock_quantity: new_stock)
        product.stock_movements.create!(
          movement_type: "restock",
          quantity_delta: quantity,
          stock_after: new_stock,
          note: I18n.t("stock_batches.movement_note", description:)
        )
        batch
      end
    end

    private

    attr_reader :product, :description, :quantity, :total_cost_cents, :received_on, :register_expense

    def parse_money(value)
      normalized = value.to_s.strip.gsub(/\s+/, "").tr(",", ".")
      (BigDecimal(normalized) * 100).round
    rescue ArgumentError
      raise InvalidBatch, I18n.t("stock_batches.invalid_values")
    end

    def create_expense
      Expense.create!(
        description:,
        category: product.code == "fishing" ? "toys" : "ingredients",
        amount_cents: total_cost_cents,
        incurred_on: received_on,
        status: "paid",
        paid_on: received_on,
        notes: I18n.t("stock_batches.expense_note", product: product.localized_name)
      )
    end
  end
end
