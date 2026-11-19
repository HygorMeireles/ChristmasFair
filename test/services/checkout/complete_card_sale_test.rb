require "test_helper"

class Checkout::CompleteCardSaleTest < ActiveSupport::TestCase
  test "records a debit sale with its configured fee and reduces stock" do
    EventSetting.current.update!(debit_card_fee_basis_points: 89)
    brownie = products(:brownie)

    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 1 do
      @order = Checkout::CompleteCardSale.call(
        quantities: { brownie: 2 },
        payment_method: "card_debit",
        checkout_token: SecureRandom.uuid
      )
    end

    assert_equal "paid", @order.status
    assert_equal "card_debit", @order.payment_method
    assert_equal 1_000, @order.total_cents
    assert_equal 89, @order.provider_fee_basis_points
    assert_equal 9, @order.provider_fee_cents
    assert_equal 991, @order.net_total_cents
    assert_equal 18, brownie.reload.stock_quantity
  end

  test "records a credit sale with its configured fee" do
    EventSetting.current.update!(credit_card_fee_basis_points: 309)

    order = Checkout::CompleteCardSale.call(
      quantities: { fishing: 1 },
      payment_method: "card_credit",
      checkout_token: SecureRandom.uuid
    )

    assert_equal 309, order.provider_fee_basis_points
    assert_equal 31, order.provider_fee_cents
    assert_equal 1, order.order_items.first.fishing_tickets.count
  end

  test "rejects an unsupported manual payment method" do
    assert_no_difference "Order.count" do
      assert_raises(Checkout::CompleteCardSale::InvalidSale) do
        Checkout::CompleteCardSale.call(
          quantities: { brownie: 1 },
          payment_method: "cash",
          checkout_token: SecureRandom.uuid
        )
      end
    end
  end
end
