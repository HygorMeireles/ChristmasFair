require "test_helper"

class Checkout::CreatePixOrderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def create_order(attempt)
      @calls += 1
      {
        "id" => "ORD-#{attempt.id}",
        "type_response" => { "qr_data" => "000201-PIX-#{attempt.id}" },
        "transactions" => { "payments" => [ { "id" => "PAY-#{attempt.id}" } ] }
      }
    end
  end

  test "creates a pending Pix order and reserves stock without reducing it" do
    client = FakeClient.new
    brownie = products(:brownie)

    assert_difference [ -> { Order.count }, -> { PaymentAttempt.count }, -> { StockReservation.count } ], 1 do
      @attempt = Checkout::CreatePixOrder.call(
        quantities: { brownie: 2 },
        checkout_token: SecureRandom.uuid,
        client:
      )
    end

    assert_equal "pending", @attempt.status
    assert_equal "pending", @attempt.order.status
    assert_equal "ORD-#{@attempt.id}", @attempt.external_order_id
    assert_equal "000201-PIX-#{@attempt.id}", @attempt.qr_data
    assert_equal 2, @attempt.order.order_items.first.stock_reservation.quantity
    assert_equal 20, brownie.reload.stock_quantity
  end

  test "reusing the checkout token does not create another provider order" do
    client = FakeClient.new
    token = SecureRandom.uuid
    attributes = { quantities: { brownie: 1 }, checkout_token: token, client: }

    first = Checkout::CreatePixOrder.call(**attributes)
    second = Checkout::CreatePixOrder.call(**attributes)

    assert_equal first, second
    assert_equal 1, client.calls
  end

  test "cash checkout cannot consume stock reserved for Pix" do
    client = FakeClient.new
    brownie = products(:brownie)
    Checkout::CreatePixOrder.call(
      quantities: { brownie: 20 },
      checkout_token: SecureRandom.uuid,
      client:
    )

    assert_raises(Checkout::CompleteCashSale::InvalidSale) do
      Checkout::CompleteCashSale.call(
        quantities: { brownie: 1 },
        amount_received_brl: "5.00",
        checkout_token: SecureRandom.uuid
      )
    end
    assert_equal 20, brownie.reload.stock_quantity
  end
end
