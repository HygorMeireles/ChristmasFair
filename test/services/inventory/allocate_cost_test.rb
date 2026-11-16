require "test_helper"

class Inventory::AllocateCostTest < ActiveSupport::TestCase
  test "allocates batch costs in entry order" do
    brownie = products(:brownie)
    brownie.update!(stock_quantity: 0)
    create_batch(brownie, "First", 2, "2.00", 2.days.ago.to_date)
    create_batch(brownie, "Second", 2, "4.00", 1.day.ago.to_date)

    order = Checkout::CompleteCashSale.call(
      quantities: { brownie: 3 },
      amount_received_brl: "15.00",
      checkout_token: SecureRandom.uuid
    )
    item = order.order_items.first

    assert_predicate item, :cost_complete?
    assert_equal 400, item.cost_cents
    assert_equal 2, item.cost_allocations.size
    assert_equal [ 0, 1 ], brownie.stock_batches.order(:received_on).pluck(:remaining_quantity)
  end

  test "marks the cost incomplete while older uncosted stock exists" do
    brownie = products(:brownie)
    create_batch(brownie, "Costed tray", 5, "10.00", Date.current)

    order = Checkout::CompleteCashSale.call(
      quantities: { brownie: 1 },
      amount_received_brl: "5.00",
      checkout_token: SecureRandom.uuid
    )
    item = order.order_items.first

    assert_not item.cost_complete?
    assert_equal 0, item.cost_cents
    assert_empty item.cost_allocations
  end

  private

  def create_batch(product, description, quantity, cost, date)
    Inventory::CreateStockBatch.call(
      product:,
      description:,
      quantity:,
      total_cost_brl: cost,
      received_on: date.to_s,
      register_expense: false
    )
  end
end
