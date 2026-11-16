require "test_helper"

class StockMovementsControllerTest < ActionDispatch::IntegrationTest
  test "registers a stock movement" do
    brownie = products(:brownie)
    assert_difference("StockMovement.count", 1) do
      post product_stock_movements_url(brownie), params: {
        direction: "add", movement_type: "restock", amount: 3, note: "Fresh batch"
      }
    end
    assert_redirected_to products_url(locale: "pt-BR")
    assert_equal 23, brownie.reload.stock_quantity
  end

  test "uses the compact add and remove actions" do
    brownie = products(:brownie)

    post product_stock_movements_url(brownie), params: { stock_action: "remove", amount: 2, note: "Damaged" }

    assert_redirected_to products_url(locale: "pt-BR")
    assert_equal 18, brownie.reload.stock_quantity
    assert_equal "loss", brownie.stock_movements.order(:created_at).last.movement_type
  end
end
