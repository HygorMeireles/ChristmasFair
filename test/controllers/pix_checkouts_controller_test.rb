require "test_helper"

class PixCheckoutsControllerTest < ActionDispatch::IntegrationTest
  test "shows a generated Pix QR inside the smartphone" do
    order = Order.create!(
      checkout_token: SecureRandom.uuid,
      status: "pending",
      payment_method: "pix",
      total_cents: 500,
      amount_received_cents: 0,
      change_cents: 0
    )
    attempt = order.payment_attempts.create!(
      public_token: SecureRandom.urlsafe_base64(24),
      status: "pending",
      idempotency_key: SecureRandom.uuid,
      external_order_id: "ORD-SHOW",
      qr_data: "000201-PIX-SHOW",
      expires_at: 15.minutes.from_now
    )

    get pix_checkout_url(attempt.public_token)

    assert_response :success
    assert_select ".real-pix-qr svg", 1
    assert_select ".pix-phone .phone-screen", 1
    assert_select "form", 0
  end

  test "fails closed when Mercado Pago is not configured" do
    with_environment(
      "MERCADO_PAGO_ACCESS_TOKEN" => "",
      "MERCADO_PAGO_EXTERNAL_POS_ID" => ""
    ) do
      assert_no_difference "StockReservation.active.count" do
        post pix_checkouts_url, params: {
          checkout: {
            checkout_token: SecureRandom.uuid,
            quantities: { brownie: 1 }
          }
        }
      end
    end

    assert_redirected_to root_url(locale: "pt-BR")
    assert_equal "cancelled", Order.last.status
    assert_equal "failed", Order.last.payment_attempts.first.status
  end

  private

  def with_environment(values)
    previous = values.to_h { |key, _value| [ key, ENV.key?(key) ? ENV[key] : :missing ] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each do |key, value|
      value == :missing ? ENV.delete(key) : ENV[key] = value
    end
  end
end
