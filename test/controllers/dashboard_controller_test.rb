require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the Portuguese cashier with all products" do
    get root_url
    assert_response :success
    assert_select "[data-controller='cart']"
    assert_select ".product-card", 3
    assert_select "h2", text: "Monte o pedido"
  end

  test "renders the English interface" do
    get root_url(locale: "en")
    assert_response :success
    assert_select "h2", text: "Build the order"
  end
end
