require "test_helper"

class StockBatchesControllerTest < ActionDispatch::IntegrationTest
  test "creates a stock batch from the settings page" do
    brownie = products(:brownie)

    assert_difference "StockBatch.count", 1 do
      post product_stock_batches_url(brownie), params: {
        stock_batch: {
          description: "Fair batch",
          quantity: 12,
          total_cost_brl: "48,00",
          received_on: Date.current,
          register_expense: "0"
        }
      }
    end

    assert_equal 32, brownie.reload.stock_quantity
    assert_redirected_to products_url(locale: "pt-BR")
  end
end
