require "test_helper"

class Inventory::AdjustStockTest < ActiveSupport::TestCase
  test "adds stock and records the resulting balance" do
    brownie = products(:brownie)
    assert_difference -> { brownie.stock_movements.count }, 1 do
      Inventory::AdjustStock.call(product: brownie, quantity_delta: 5, movement_type: "restock", note: "Second tray")
    end
    assert_equal 25, brownie.reload.stock_quantity
    assert_equal 25, brownie.stock_movements.order(:created_at).last.stock_after
  end

  test "refuses to remove more than the available stock" do
    brownie = products(:brownie)
    assert_no_changes -> { brownie.reload.stock_quantity } do
      assert_raises(Inventory::AdjustStock::InvalidAdjustment) do
        Inventory::AdjustStock.call(product: brownie, quantity_delta: -21, movement_type: "loss")
      end
    end
  end

  test "refuses chocolate above configured capacity" do
    chocolate = products(:hot_chocolate)
    assert_raises(Inventory::AdjustStock::InvalidAdjustment) do
      Inventory::AdjustStock.call(product: chocolate, quantity_delta: 1, movement_type: "restock")
    end
  end
end
