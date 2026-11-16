require "test_helper"

class Checkout::CancelPixOrderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :cancelled_id, :idempotency_key

    def create_order(attempt)
      {
        "id" => "ORD-#{attempt.id}",
        "type_response" => { "qr_data" => "000201-PIX-#{attempt.id}" },
        "transactions" => { "payments" => [ { "id" => "PAY-#{attempt.id}" } ] }
      }
    end

    def cancel_order(external_order_id, idempotency_key:)
      @cancelled_id = external_order_id
      @idempotency_key = idempotency_key
      { "id" => external_order_id, "status" => "canceled", "status_detail" => "canceled_by_api" }
    end
  end

  test "cancels the provider order and releases reserved stock" do
    client = FakeClient.new
    attempt = Checkout::CreatePixOrder.call(
      quantities: { brownie: 2 },
      checkout_token: SecureRandom.uuid,
      client:
    )

    Checkout::CancelPixOrder.call(attempt:, client:)

    assert_equal attempt.external_order_id, client.cancelled_id
    assert_equal attempt.cancel_idempotency_key, client.idempotency_key
    assert_equal "cancelled", attempt.reload.status
    assert_equal "cancelled", attempt.order.reload.status
    assert_equal [ "released" ], attempt.order.order_items.map { |item| item.stock_reservation.status }.uniq
    assert_equal 20, products(:brownie).reload.stock_quantity
  end
end
