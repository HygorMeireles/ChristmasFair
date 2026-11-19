require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "shows compact stock controls and a usable Mercado Pago fee field" do
    get products_url

    assert_response :success
    assert_select ".event-settings-form .fee-input input[value='1.00']", 1
    assert_select ".event-settings-form .fee-input input[value='0.89']", 1
    assert_select ".event-settings-form .fee-input input[value='3.09']", 1
    assert_select ".quick-stock-form", 3
    assert_select ".quick-stock-form select", 0
    assert_select "button[name='stock_action'][value='add']", 3
    assert_select "button[name='stock_action'][value='remove']", 3
    assert_select "details.product-config-panel", 3
  end

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
