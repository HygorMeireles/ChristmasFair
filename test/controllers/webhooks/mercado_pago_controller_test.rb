require "test_helper"

class Webhooks::MercadoPagoControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_secret = ENV["MERCADO_PAGO_WEBHOOK_SECRET"]
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = "webhook-test-secret"
  end

  teardown do
    ENV["MERCADO_PAGO_WEBHOOK_SECRET"] = @original_secret
  end

  test "accepts a valid signed order notification once" do
    resource_id = "ORD-WEBHOOK-1"
    request_id = SecureRandom.uuid
    timestamp = (Time.current.to_f * 1000).to_i.to_s
    manifest = "id:#{resource_id};request-id:#{request_id};ts:#{timestamp};"
    signature = OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("MERCADO_PAGO_WEBHOOK_SECRET"), manifest)
    headers = {
      "CONTENT_TYPE" => "application/json",
      "x-request-id" => request_id,
      "x-signature" => "ts=#{timestamp},v1=#{signature}"
    }
    payload = { id: "event-1", action: "order.processed", type: "order", data: { id: resource_id } }

    assert_difference "PaymentEvent.count", 1 do
      assert_enqueued_with(job: ProcessMercadoPagoOrderJob) do
        post mercado_pago_webhook_url, params: payload.to_json, headers:
      end
    end
    assert_response :success
  end

  test "rejects an invalid signature" do
    post mercado_pago_webhook_url,
      params: { type: "order", data: { id: "ORD-INVALID" } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "x-request-id" => "request", "x-signature" => "ts=1,v1=bad" }

    assert_response :unauthorized
    assert_equal 0, PaymentEvent.count
  end
end
