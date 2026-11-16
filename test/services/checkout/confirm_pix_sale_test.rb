require "test_helper"

class Checkout::ConfirmPixSaleTest < ActiveSupport::TestCase
  setup do
    fake_client = Object.new
    fake_client.define_singleton_method(:create_order) do |attempt|
      {
        "id" => "ORD-#{attempt.id}",
        "type_response" => { "qr_data" => "000201-PIX-#{attempt.id}" },
        "transactions" => { "payments" => [ { "id" => "PAY-#{attempt.id}" } ] }
      }
    end
    @attempt = Checkout::CreatePixOrder.call(
      quantities: { brownie: 1, fishing: 2 },
      checkout_token: SecureRandom.uuid,
      client: fake_client
    )
  end

  test "confirms the Pix sale and consumes reserved stock once" do
    data = approved_provider_data(@attempt)

    assert_difference -> { StockMovement.count } => 2, -> { FishingTicket.count } => 2 do
      Checkout::ConfirmPixSale.call(attempt: @attempt, provider_data: data)
    end

    assert_predicate @attempt.order.reload, :paid?
    assert_predicate @attempt.reload, :approved?
    assert_equal 19, products(:brownie).reload.stock_quantity
    assert_equal 13, products(:fishing).reload.stock_quantity
    assert @attempt.order.order_items.all? { |item| item.stock_reservation.status == "confirmed" }

    assert_no_difference [ -> { StockMovement.count }, -> { FishingTicket.count } ] do
      Checkout::ConfirmPixSale.call(attempt: @attempt, provider_data: data)
    end
  end

  test "rejects a provider confirmation with a different amount" do
    data = approved_provider_data(@attempt).merge("total_amount" => "1.00")

    assert_raises(Checkout::ConfirmPixSale::InvalidConfirmation) do
      Checkout::ConfirmPixSale.call(attempt: @attempt, provider_data: data)
    end
    assert_equal "pending", @attempt.order.reload.status
    assert_equal 20, products(:brownie).reload.stock_quantity
  end

  private

  def approved_provider_data(attempt)
    {
      "id" => attempt.external_order_id,
      "external_reference" => "christmas_fair_order_#{attempt.order_id}",
      "status" => "processed",
      "status_detail" => "accredited",
      "total_amount" => format("%.2f", attempt.order.total_cents / 100.0)
    }
  end
end
