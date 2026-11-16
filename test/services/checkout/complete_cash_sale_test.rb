require "test_helper"

class Checkout::CompleteCashSaleTest < ActiveSupport::TestCase
  test "records a mixed cash sale and reduces each product stock" do
    brownie = products(:brownie)
    chocolate = products(:hot_chocolate)

    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 2 do
      @order = Checkout::CompleteCashSale.call(
        quantities: { brownie: 2, hot_chocolate: 1, fishing: 0 },
        amount_received_brl: "20,00",
        checkout_token: SecureRandom.uuid
      )
    end

    assert_equal 1_700, @order.total_cents
    assert_equal 2_000, @order.amount_received_cents
    assert_equal 300, @order.change_cents
    assert_equal "paid", @order.status
    assert_equal "cash", @order.payment_method
    assert_equal 18, brownie.reload.stock_quantity
    assert_equal 4_750, chocolate.reload.stock_quantity
    assert_equal(-2, brownie.stock_movements.order(:created_at).last.quantity_delta)
    assert_equal(-250, chocolate.stock_movements.order(:created_at).last.quantity_delta)
  end

  test "does not change stock when the cash received is insufficient" do
    brownie = products(:brownie)

    assert_no_difference [ -> { Order.count }, -> { OrderItem.count }, -> { StockMovement.count } ] do
      assert_raises(Checkout::CompleteCashSale::InvalidSale) do
        Checkout::CompleteCashSale.call(
          quantities: { brownie: 2 },
          amount_received_brl: "5.00",
          checkout_token: SecureRandom.uuid
        )
      end
    end

    assert_equal 20, brownie.reload.stock_quantity
  end

  test "does not sell more than the available stock" do
    assert_no_difference "Order.count" do
      assert_raises(Checkout::CompleteCashSale::InvalidSale) do
        Checkout::CompleteCashSale.call(
          quantities: { brownie: 21 },
          amount_received_brl: "200.00",
          checkout_token: SecureRandom.uuid
        )
      end
    end
  end

  test "reusing the checkout token does not duplicate the sale" do
    token = SecureRandom.uuid
    attributes = { quantities: { fishing: 1 }, amount_received_brl: "10", checkout_token: token }

    first_order = Checkout::CompleteCashSale.call(**attributes)
    assert_no_difference [ -> { Order.count }, -> { OrderItem.count }, -> { StockMovement.count } ] do
      second_order = Checkout::CompleteCashSale.call(**attributes)
      assert_equal first_order, second_order
    end
  end

  test "creates one redeemable ticket for each fishing game sold" do
    assert_difference "FishingTicket.count", 2 do
      order = Checkout::CompleteCashSale.call(
        quantities: { fishing: 2 },
        amount_received_brl: "20.00",
        checkout_token: SecureRandom.uuid
      )

      assert_equal 2, order.order_items.first.fishing_tickets.size
      assert order.order_items.first.fishing_tickets.all?(&:pending?)
    end
  end
end
