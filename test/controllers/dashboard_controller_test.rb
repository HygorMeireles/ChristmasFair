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
    assert_select ".product-stage > form.order-checkout-card", 1
    assert_select ".checkout-panel .phone-ready form", 0
    assert_select ".checkout-panel .phone-ready h3", text: "Pagamento Pix"
    assert_select "input[data-cart-target='checkoutButton'][disabled]", 1
    assert_select "button[data-action='cart#confirmOrder']", text: "Confirmar pedido"
    assert_select "button[formaction=?]", pix_checkouts_path(locale: "pt-BR"), text: "Gerar QR Pix"
    assert_select "button[data-cart-target='pixMethod'].selected", text: "Pix"
    assert_select "button[data-cart-target='debitMethod']", text: "Débito"
    assert_select "button[data-cart-target='creditMethod']", text: "Crédito"
    assert_select "button[formaction=?]", card_checkouts_path(locale: "pt-BR"), text: "Pagamento aprovado"
    assert_select "form[data-action='submit->cart#submitCheckout']", 1
    assert_select "[data-cart-target='paymentState'][hidden]", 1
    assert_select "a[href=?]", fishing_tickets_path(locale: "pt-BR"), text: "Pescaria"
    assert_select "a[href=?]", financial_path(locale: "pt-BR"), text: "Financeiro"
    assert_select "a[href=?][target='_blank']", root_path(customer_display: 1, locale: "pt-BR"), text: "Tela do cliente"
    assert_select "button[data-action='display#toggle']", text: "Congelar tela"
  end

  test "renders the English interface" do
    get root_url(locale: "en")
    assert_response :success
    assert_select "h2", text: "Build the order"
  end

  test "renders a read-only customer display mode" do
    get root_url(customer_display: 1)

    assert_response :success
    assert_select "body.customer-display-mode[data-display-customer-value='true']", 1
    assert_select "[data-controller='cart'][data-cart-display-only-value='true']", 1
  end

  test "shows a dismissible payment result modal" do
    get root_url(payment: "approved")

    assert_response :success
    assert_select "dialog.payment-result-modal.approved[data-controller='payment-modal']", 1
    assert_select ".payment-result-modal h2", text: "Venda concluída!"
    assert_select "button[data-action='payment-modal#close']", 1
  end

  test "shows a card payment confirmation modal" do
    get root_url(payment: "card_approved")

    assert_response :success
    assert_select "dialog.payment-result-modal.card_approved", 1
    assert_select ".payment-result-modal p", text: /pagamento por aproximação/
  end
end
