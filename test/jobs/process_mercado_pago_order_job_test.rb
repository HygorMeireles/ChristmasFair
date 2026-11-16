require "test_helper"

class ProcessMercadoPagoOrderJobTest < ActiveJob::TestCase
  test "ignores a valid notification for an order not created by this application" do
    event = PaymentEvent.create!(event_key: SecureRandom.uuid, resource_id: "ORD-UNKNOWN", payload: {})

    assert_nothing_raised do
      ProcessMercadoPagoOrderJob.perform_now("ORD-UNKNOWN", event.id)
    end

    assert_predicate event.reload, :processed_at?
    assert_match(/unknown Mercado Pago order/, event.error_message)
  end
end
