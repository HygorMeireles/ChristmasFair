require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the Portuguese cashier with all products" do
    get root_url
    assert_response :success
    assert_select "[data-controller='cart']"
    assert_select ".product-card", 3
    assert_select "img.event-logo[alt='Mister Wiz Christmas Fair']", 1
    assert_select "link[rel='icon'][href*='mister-wiz-symbol']", 1
    assert_select "h2", text: "Monte o pedido"
    assert_select "form.cash-checkout-form[action=?]", cash_checkouts_path(locale: "pt-BR")
    assert_select "input[data-cart-target='checkoutButton'][disabled]", 1
    assert_select "a[href=?]", fishing_tickets_path(locale: "pt-BR"), text: "Pescaria"
    assert_select "a[href=?]", financial_path(locale: "pt-BR"), text: "Financeiro"
  end

  test "renders the English interface" do
    get root_url(locale: "en")
    assert_response :success
    assert_select "h2", text: "Build the order"
  end
end
