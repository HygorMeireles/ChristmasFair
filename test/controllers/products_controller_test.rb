require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "updates configurable price and serving size" do
    chocolate = products(:hot_chocolate)
    patch product_url(chocolate), params: { product: {
      name_pt: chocolate.name_pt, name_en: chocolate.name_en, price_brl: "8,50",
      capacity_quantity: 5_000, serving_size: 200, active: true
    } }
    assert_redirected_to products_url(locale: "pt-BR")
    assert_equal 850, chocolate.reload.price_cents
    assert_equal 200, chocolate.serving_size
  end
end
