module Inventory
  class AllocateCost
    def self.call(order_item:, quantity:)
      new(order_item:, quantity:).call
    end

    def initialize(order_item:, quantity:)
      @order_item = order_item
      @quantity = quantity
    end

    def call
      batches = order_item.product.stock_batches.available.fifo.lock.to_a
      batched_stock = batches.sum(&:remaining_quantity)
      uncosted_stock = [ order_item.product.stock_quantity - batched_stock, 0 ].max
      remaining = [ quantity - uncosted_stock, 0 ].max
      allocated_cost = 0

      batches.each do |batch|
        break if remaining.zero?

        used = [ remaining, batch.remaining_quantity ].min
        cost = allocation_cost(batch, used)
        batch.update!(
          remaining_quantity: batch.remaining_quantity - used,
          allocated_cost_cents: batch.allocated_cost_cents + cost
        )
        order_item.cost_allocations.create!(stock_batch: batch, quantity: used, cost_cents: cost)
        remaining -= used
        allocated_cost += cost
      end

      order_item.update!(
        cost_cents: allocated_cost,
        cost_complete: uncosted_stock.zero? && remaining.zero?
      )
    end

    private

    attr_reader :order_item, :quantity

    def allocation_cost(batch, used)
      return batch.total_cost_cents - batch.allocated_cost_cents if used == batch.remaining_quantity

      (batch.total_cost_cents.to_d * used / batch.initial_quantity).round
    end
  end
end
