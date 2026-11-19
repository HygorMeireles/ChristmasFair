require "test_helper"

class CardCheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "completes a confirmed debit checkout" do
    assert_difference "Order.count", 1 do
      post card_checkouts_url, params: {
        checkout: {
          checkout_token: SecureRandom.uuid,
          payment_method: "card_debit",
          quantities: { brownie: 1, hot_chocolate: 1, fishing: 0 }
        }
      }
    end

    assert_redirected_to root_url(locale: "pt-BR", payment: "card_approved")
    assert_equal "card_debit", Order.order(:created_at).last.payment_method
  end

  test "rejects a card checkout without a card method" do
    assert_no_difference "Order.count" do
      post card_checkouts_url, params: {
        checkout: {
          checkout_token: SecureRandom.uuid,
          payment_method: "pix",
          quantities: { brownie: 1 }
        }
      }
    end

    assert_redirected_to root_url(locale: "pt-BR")
  end
end
