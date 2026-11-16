require "test_helper"

class Inventory::CreateStockBatchTest < ActiveSupport::TestCase
  test "adds costed stock and optionally records the purchase as an expense" do
    brownie = products(:brownie)

    assert_difference [ -> { StockBatch.count }, -> { Expense.count }, -> { StockMovement.count } ], 1 do
      @batch = Inventory::CreateStockBatch.call(
        product: brownie,
        description: "First brownie tray",
        quantity: 10,
        total_cost_brl: "30,00",
        received_on: Date.current.to_s,
        register_expense: true
      )
    end

    assert_equal 30, brownie.reload.stock_quantity
    assert_equal 3_000, @batch.total_cost_cents
    assert_equal 10, @batch.remaining_quantity
    assert_equal @batch.expense, Expense.last
    assert_predicate @batch.expense, :paid?
  end

  test "refuses a chocolate batch above the bottle capacity" do
    chocolate = products(:hot_chocolate)

    assert_no_difference [ -> { StockBatch.count }, -> { Expense.count }, -> { StockMovement.count } ] do
      assert_raises(Inventory::CreateStockBatch::InvalidBatch) do
        Inventory::CreateStockBatch.call(
          product: chocolate,
          description: "Extra bottle",
          quantity: 250,
          total_cost_brl: "10.00",
          received_on: Date.current.to_s,
          register_expense: true
        )
      end
    end
  end
end
