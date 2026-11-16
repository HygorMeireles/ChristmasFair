require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "calculates servings and percentage with integer stock" do
    product = products(:hot_chocolate)
    assert_equal 20, product.available_servings
    assert_equal 100.0, product.stock_percentage
  end

  test "does not allow chocolate above bottle capacity" do
    product = products(:hot_chocolate)
    product.stock_quantity = 5_001
    assert_not product.valid?
    assert product.errors[:stock_quantity].any?
  end

  test "parses Brazilian price without floating point storage" do
    product = products(:brownie)
    product.price_brl = "12,50"
    assert_equal 1_250, product.price_cents
  end
end
