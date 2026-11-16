require "test_helper"

class CashCheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "completes a cash checkout" do
    assert_difference "Order.count", 1 do
      post cash_checkouts_url, params: {
        checkout: {
          checkout_token: SecureRandom.uuid,
          amount_received_brl: "20.00",
          quantities: { brownie: 1, hot_chocolate: 1, fishing: 0 }
        }
      }
    end

    assert_redirected_to root_url(locale: "pt-BR")
    follow_redirect!
    assert_select ".flash.notice", /Venda #/
  end

  test "rejects a checkout without enough cash" do
    assert_no_difference "Order.count" do
      post cash_checkouts_url, params: {
        checkout: {
          checkout_token: SecureRandom.uuid,
          amount_received_brl: "1.00",
          quantities: { brownie: 1 }
        }
      }
    end

    assert_redirected_to root_url(locale: "pt-BR")
  end
end
